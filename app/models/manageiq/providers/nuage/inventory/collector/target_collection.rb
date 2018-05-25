class ManageIQ::Providers::Nuage::Inventory::Collector::TargetCollection < ManageIQ::Providers::Nuage::Inventory::Collector
  def initialize(_manager, _target)
    super
    initialize_cache
    parse_targets!
    infer_related_ems_refs!

    # Reset the target cache, so we can access new targets inside
    target.manager_refs_by_association_reset
  end

  def cloud_subnets
    return [] if references(:cloud_subnets).blank?
    references(:cloud_subnets).collect { |ems_ref| cloud_subnet(ems_ref) }
    @cloud_subnets_map.values.compact
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

  def cloud_subnet(ems_ref)
    return @cloud_subnets_map[ems_ref] if @cloud_subnets_map.key?(ems_ref)
    @cloud_subnets_map[ems_ref] = safe_call { vsd_client.get_subnet(ems_ref) }
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

  def domain(ems_ref)
    return @domains_map[ems_ref] if @domains_map.key?(ems_ref)
    @domains_map[ems_ref] = safe_call { vsd_client.get_domain(ems_ref) }
  end

  private

  def initialize_cache
    @cloud_subnets_map   = {}
    @security_groups_map = {}
    @cloud_tenant_map    = {}
    @zones_map           = {}
    @domains_map         = {}
    @domains_per_tenant  = {}
  end

  def domains_for_tenant(tenant_ems_ref)
    ems_ref = tenant_ems_ref
    @domains_per_tenant[ems_ref] ||= safe_list { vsd_client.get_domains_for_enterprise(ems_ref) }
    @domains_per_tenant[ems_ref].each { |d| @domains_map[d['ID']] = d }
    @domains_per_tenant[ems_ref]
  end

  def cloud_subnets_for_tenant(tenant_ems_ref)
    domains_for_tenant(tenant_ems_ref).each_with_object([]) do |d, arr|
      arr.push(safe_list { vsd_client.get_subnets_for_domain(d['ID']) })
    end.flatten(1)
  end

  def security_groups_for_tenant(tenant_ems_ref)
    domains_for_tenant(tenant_ems_ref).each_with_object([]) do |d, arr|
      arr.push(safe_list { vsd_client.get_policy_groups_for_domain(d['ID']) })
    end.flatten(1)
  end

  def tenant_ems_ref_for_cloud_subnet(cloud_subnet_ems_ref)
    cloud_subnet = cloud_subnet(cloud_subnet_ems_ref)
    return nil if cloud_subnet.nil?
    domain_ems_ref = zone(cloud_subnet['parentID'])['parentID']
    domain(domain_ems_ref)['parentID']
  end

  def tenant_ems_ref_for_security_group(security_group_ems_ref)
    security_group = security_group(security_group_ems_ref)
    return nil if security_group.nil?
    domain(security_group['parentID'])['parentID']
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
    if references(:cloud_tenants).any?
      tenants = manager.cloud_tenants.where(:ems_ref => references(:cloud_tenants))
                              .includes(:cloud_subnets, :security_groups)
      tenants.each do |tenant|
        tenant.cloud_subnets.collect(&:ems_ref).compact.each { |ems_ref| add_simple_target!(:cloud_subnets, ems_ref) }
        tenant.security_groups.collect(&:ems_ref).compact.each { |ems_ref| add_simple_target!(:security_groups, ems_ref) }
      end
    end

    if references(:cloud_subnets).any?
      cloud_subnets = manager.cloud_subnets.where(:ems_ref => references(:cloud_subnets))
      cloud_subnets.each do |cloud_subnet|
        next if cloud_subnet.cloud_tenant.nil?
        add_simple_target!(:cloud_tenants, cloud_subnet.cloud_tenant.ems_ref)
        cloud_subnet.cloud_tenant.security_groups.each do |security_group|
          add_simple_target!(:security_groups, security_group.ems_ref)
        end
      end
    end

    if references(:security_groups).any?
      security_groups = manager.security_groups.where(:ems_ref => references(:security_groups))
      security_groups.each do |security_group|
        add_simple_target!(:cloud_tenants, security_group.cloud_tenant.ems_ref) unless security_group.cloud_tenant.nil?
      end
    end
  end

  def infer_related_ems_refs_api!
    references(:cloud_tenants).each do |tenant_ems_ref|
      cloud_subnets_for_tenant(tenant_ems_ref).each do |cloud_subnet|
        add_simple_target!(:cloud_subnets, cloud_subnet['ID'])
      end

      security_groups_for_tenant(tenant_ems_ref).each do |policy_group|
        add_simple_target!(:security_groups, policy_group['ID'])
      end
    end

    references(:cloud_subnets).each do |cs_ems_ref|
      tenant_ems_ref = tenant_ems_ref_for_cloud_subnet(cs_ems_ref)
      next if tenant_ems_ref.nil?
      add_simple_target!(:cloud_tenants, tenant_ems_ref)
      security_groups_for_tenant(tenant_ems_ref).each do |policy_group|
        add_simple_target!(:security_groups, policy_group['ID'])
      end
    end

    references(:security_groups).each do |sg_ems_ref|
      add_simple_target!(:cloud_tenants, tenant_ems_ref_for_security_group(sg_ems_ref))
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
end
