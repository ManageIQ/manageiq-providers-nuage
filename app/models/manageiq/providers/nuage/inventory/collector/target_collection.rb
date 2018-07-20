class ManageIQ::Providers::Nuage::Inventory::Collector::TargetCollection < ManageIQ::Providers::Nuage::Inventory::Collector
  def initialize(_manager, _target)
    super
    initialize_cache
    parse_targets!
    infer_related_ems_refs!

    # Reset the target cache, so we can access new targets inside
    target.manager_refs_by_association_reset
  end

  def cloud_networks_floating
    return [] if references(:cloud_networks).blank?
    references(:cloud_networks).collect { |ems_ref| shared_resource(ems_ref) }
    @shared_resources_map.values.compact.select { |res| res['type'] == 'FLOATING' }
  end

  def cloud_subnets
    return [] if (refs = references_with_kind(:cloud_subnets, 'L3')).blank?
    refs.map { |ems_ref| cloud_subnet(ems_ref) }.compact
  end

  def l2_cloud_subnets
    return [] if (refs = references_with_kind(:cloud_subnets, 'L2')).blank?
    refs.map { |ems_ref| l2_cloud_subnet(ems_ref) }.compact
  end

  def security_groups
    return [] if references(:security_groups).blank?
    references(:security_groups).collect { |ems_ref| security_group(ems_ref) }
    @security_groups_map.values.compact
  end

  def cloud_tenants
    return [] if references(:cloud_tenants).blank?
    references(:cloud_tenants).collect { |ems_ref| cloud_tenant(ems_ref) }
    @cloud_tenant_map.values.compact
  end

  def network_routers
    return [] if references(:network_routers).blank?
    references(:network_routers).collect { |ems_ref| network_router(ems_ref) }
    @network_routers_map.values.compact
  end

  def floating_ips
    [] # TODO(miha-plesko): implement targeted refresh for floating ips
  end

  def network_ports
    [] # TODO(miha-plesko): implement targeted refresh for network_ports
  end

  def security_groups_for_network_port(_port_ems_ref)
    [] # TODO(miha-plesko): implement targeted refresh for network_ports
  end

  def cloud_subnet(ems_ref)
    return @cloud_subnets_map[ems_ref] if @cloud_subnets_map.key?(ems_ref)
    @cloud_subnets_map[ems_ref] = safe_call { vsd_client.get_subnet(ems_ref) }
  end

  def l2_cloud_subnet(ems_ref)
    return @l2_cloud_subnets_map[ems_ref] if @l2_cloud_subnets_map.key?(ems_ref)
    @l2_cloud_subnets_map[ems_ref] = safe_call { vsd_client.get_l2_domain(ems_ref) }
  end

  def shared_resource(ems_ref)
    return @shared_resources_map[ems_ref] if @shared_resources_map.key?(ems_ref)
    @shared_resources_map[ems_ref] = safe_call { vsd_client.get_sharednetworkresource(ems_ref) }
  end

  def security_group(ems_ref)
    return @security_groups_map[ems_ref] if @security_groups_map.key?(ems_ref)
    @security_groups_map[ems_ref] = safe_call { vsd_client.get_policy_group(ems_ref) }
  end

  def cloud_tenant(ems_ref)
    return @cloud_tenant_map[ems_ref] if @cloud_tenant_map.key?(ems_ref)
    @cloud_tenant_map[ems_ref] = safe_call { vsd_client.get_enterprise(ems_ref) }
  end

  def zone(ems_ref)
    return @zones_map[ems_ref] if @zones_map.key?(ems_ref)
    @zones_map[ems_ref] = safe_call { vsd_client.get_zone(ems_ref) }
  end

  def network_router(ems_ref)
    return @network_routers_map[ems_ref] if @network_routers_map.key?(ems_ref)
    @network_routers_map[ems_ref] = safe_call { vsd_client.get_domain(ems_ref) }
  end

  private

  def initialize_cache
    @cloud_subnets_map    = {}
    @security_groups_map  = {}
    @cloud_tenant_map     = {}
    @zones_map            = {}
    @network_routers_map  = {}
    @routers_per_tenant   = {}
    @shared_resources_map = {}
    @l2_cloud_subnets_map = {}
  end

  def routers_for_tenant(tenant_ems_ref)
    ems_ref = tenant_ems_ref
    @routers_per_tenant[ems_ref] ||= safe_list { vsd_client.get_domains_for_enterprise(ems_ref) }
    @routers_per_tenant[ems_ref].each { |d| @network_routers_map[d['ID']] = d }
    @routers_per_tenant[ems_ref]
  end

  def cloud_subnets_for_tenant(tenant_ems_ref)
    routers_for_tenant(tenant_ems_ref).each_with_object([]) do |d, arr|
      arr.push(safe_list { vsd_client.get_subnets_for_domain(d['ID']) })
    end.flatten(1)
  end

  def security_groups_for_tenant(tenant_ems_ref)
    routers_for_tenant(tenant_ems_ref).each_with_object([]) do |d, arr|
      arr.push(safe_list { vsd_client.get_policy_groups_for_domain(d['ID']) })
    end.flatten(1)
  end

  def tenant_ems_ref_for_cloud_subnet(cloud_subnet_ems_ref)
    cloud_subnet = cloud_subnet(cloud_subnet_ems_ref)
    return nil if cloud_subnet.nil?
    router_ems_ref = zone(cloud_subnet['parentID'])['parentID']
    network_router(router_ems_ref)['parentID']
  end

  def tenant_ems_ref_for_security_group(security_group_ems_ref)
    security_group = security_group(security_group_ems_ref)
    return nil if security_group.nil?
    network_router(security_group['parentID'])['parentID']
  end

  def references(collection)
    target.manager_refs_by_association.try(:[], collection).try(:[], :ems_ref).try(:to_a) || []
  end

  def parse_targets!
    target.targets.each do |t|
      case t
      when CloudSubnet
        add_simple_target!(:cloud_subnets, t.ems_ref)
      when SecurityGroup
        add_simple_target!(:security_groups, t.ems_ref)
      when CloudTenant
        add_simple_target!(:cloud_tenants, t.ems_ref)
      when NetworkRouter
        add_simple_target!(:network_routers, t.ems_ref)
      end
    end
  end

  def add_simple_target!(association, ems_ref)
    return if ems_ref.blank?

    target.add_target(:association => association, :manager_ref => {:ems_ref => ems_ref})
  end

  def infer_related_ems_refs!
    infer_related_ems_refs_db!
    infer_related_ems_refs_api!
  end

  def infer_related_ems_refs_db!
    # infer related entities based on VMDB here if needed
  end

  def infer_related_ems_refs_api!
    # infer related entities based on Nuage API here if needed
  end

  def safe_call
    response = yield

    # TODO: This error handling is funny because the vsd_client returns 'true' when any other status than 200 is
    # returned :) We need to refactor the vsd_client and then rescue from actual errors here...
    case response
    when Array, Hash
      response
    end
  end

  def safe_list(&block)
    safe_call(&block) || []
  end

  def references_with_kind(association, kind)
    target.targets.select { |t| t.association == association && t.options[:kind] == kind }.map { |t| t.manager_ref[:ems_ref] }
  end
end
