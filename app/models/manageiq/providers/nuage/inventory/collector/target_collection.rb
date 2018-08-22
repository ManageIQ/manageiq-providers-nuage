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
    refs.map { |subnet| cloud_subnet(subnet[:ems_ref]) }.compact
  end

  def l2_cloud_subnets
    return [] if (refs = references_with_kind(:cloud_subnets, 'L2')).blank?
    refs.map { |subnet| l2_cloud_subnet(subnet[:ems_ref]) }.compact
  end

  def security_groups
    return [] if (refs = references(:security_groups)).blank?
    refs.map { |ems_ref| security_group(ems_ref) }.compact
  end

  def cloud_tenants
    return [] if (refs = references(:cloud_tenants)).blank?
    refs.map { |ems_ref| cloud_tenant(ems_ref) }.compact
  end

  def network_routers
    return [] if (refs = references(:network_routers)).blank?
    refs.map { |ems_ref| network_router(ems_ref) }.compact
  end

  def floating_ips
    return [] if (refs = references(:floating_ips)).blank?
    refs.map { |ems_ref| floating_ip(ems_ref) }.compact
  end

  def network_ports
    return [] if (refs = references(:network_ports)).blank?
    refs.map { |ems_ref| network_port(ems_ref) }.compact
  end

  def security_groups_for_network_port(port_ems_ref)
    safe_call { vsd_client.get_policy_groups_for_vport(port_ems_ref) }
  end

  def vm_interfaces_for_network_port(port_ems_ref)
    safe_call { vsd_client.get_vm_interfaces_for_vport(port_ems_ref) }
  end

  def container_interfaces_for_network_port(port_ems_ref)
    safe_call { vsd_client.get_container_interfaces_for_vport(port_ems_ref) }
  end

  def host_interfaces_for_network_port(port_ems_ref)
    safe_call { vsd_client.get_host_interfaces_for_vport(port_ems_ref) }
  end

  def cloud_subnet(ems_ref)
    safe_call { vsd_client.get_subnet(ems_ref) }
  end

  def l2_cloud_subnet(ems_ref)
    safe_call { vsd_client.get_l2_domain(ems_ref) }
  end

  def shared_resource(ems_ref)
    return @shared_resources_map[ems_ref] if @shared_resources_map.key?(ems_ref)
    @shared_resources_map[ems_ref] = safe_call { vsd_client.get_sharednetworkresource(ems_ref) }
  end

  def security_group(ems_ref)
    safe_call { vsd_client.get_policy_group(ems_ref) }
  end

  def cloud_tenant(ems_ref)
    safe_call { vsd_client.get_enterprise(ems_ref) }
  end

  def zone(ems_ref)
    safe_call { vsd_client.get_zone(ems_ref) }
  end

  def network_router(ems_ref)
    safe_call { vsd_client.get_domain(ems_ref) }
  end

  def floating_ip(ems_ref)
    safe_call { vsd_client.get_floating_ip(ems_ref) }
  end

  def network_port(ems_ref)
    safe_call { vsd_client.get_vport(ems_ref) }
  end

  private

  def initialize_cache
    @shared_resources_map = {}
  end

  def cloud_subnets_for_router(router_ref)
    safe_list { vsd_client.get_subnets_for_domain(router_ref) }
  end

  def routers_for_tenant(tenant_ems_ref)
    safe_list { vsd_client.get_domains_for_enterprise(tenant_ems_ref) }
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

  def add_simple_target!(association, ems_ref, options: {})
    return if ems_ref.blank?

    target.add_target(:association => association, :manager_ref => {:ems_ref => ems_ref}, :options => options)
  end

  def infer_related_ems_refs!
    infer_related_ems_refs_db!
    infer_related_ems_refs_api!
  end

  def infer_related_ems_refs_db!
    references_with_options(:cloud_subnet_templates).each do |template|
      next unless template[:operation] == 'DELETE'
      manager.cloud_subnets_by_extra_attr('template_id', template[:ems_ref]).each do |subnet|
        add_simple_target!(:cloud_subnets, subnet.ems_ref, :options => { :kind => 'L3', :deleted => true })
      end
    end
  end

  def infer_related_ems_refs_api!
    # Overcome Nuage glitch upon router template instantiation.
    # GLITCH: even if template contains subnets, no "subnet create" event is emitted hence targeted
    # refresh isn't triggered for those.
    # SOLUTION: manually infer all subnets for such router.
    references_with_options(:network_routers).each do |router|
      next unless router[:operation] == 'CREATE'
      cloud_subnets_for_router(router[:ems_ref]).each do |subnet|
        add_simple_target!(:cloud_subnets, subnet['ID'], :options => { :kind => 'L3' })
      end
    end

    references(:network_ports).each do |port|
      case port['parentType']
      when 'subnet'
        add_simple_target!(:cloud_subnets, port['parentID'], :options => { :kind => 'L3' })
      when 'l2domain'
        add_simple_target!(:cloud_subnets, port['parentID'], :options => { :kind => 'L2' })
      end
    end
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
    references_with_options(association).select { |t| t[:kind] == kind }
  end

  def references_with_options(association)
    target.targets
          .select { |t| t.association == association }
          .map    { |t| t.options.merge(:ems_ref => t.manager_ref[:ems_ref]) }
          .reject { |t| t[:deleted] } # Sometimes we know it is deleted, so we spare an API call for performance reasons.
  end
end
