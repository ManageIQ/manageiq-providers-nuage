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

  def vms_for_network_port(port_ems_ref)
    safe_call { vsd_client.get_vms_for_vport(port_ems_ref) }
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

  def parse_targets!
    # parse native targets (e.g. CloudSubnet::L3) here in case we support manual triggering targeted refresh for them.
  end

  def infer_related_ems_refs!
    infer_related_ems_refs_db!
    infer_related_ems_refs_api!
  end

  def infer_related_ems_refs_db!
    references_with_options(:cloud_subnet_templates).each do |template|
      next unless template[:operation] == 'DELETE'
      manager.cloud_subnets_by_extra_attr('template_id', template[:ems_ref]).each do |subnet|
        add_target!(:cloud_subnets, subnet.ems_ref, :kind => 'L3', :deleted => true)
      end
    end

    references_with_options(:zone_templates).each do |template|
      next unless template[:operation] == 'DELETE'
      manager.cloud_subnets_by_extra_attr('zone_template_id', template[:ems_ref]).each do |subnet|
        add_target!(:cloud_subnets, subnet.ems_ref, :kind => 'L3', :deleted => true)
      end
    end

    references_with_options(:zones).each do |zone|
      next unless zone[:operation] == 'DELETE'
      manager.cloud_subnets_by_extra_attr('zone_id', zone[:ems_ref]).each do |subnet|
        add_target!(:cloud_subnets, subnet.ems_ref, :kind => 'L3', :deleted => true)
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
        add_target!(:cloud_subnets, subnet['ID'], :kind => 'L3')
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
