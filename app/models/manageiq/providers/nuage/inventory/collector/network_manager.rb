class ManageIQ::Providers::Nuage::Inventory::Collector::NetworkManager < ManageIQ::Providers::Nuage::Inventory::Collector
  def cloud_tenants
    vsd_client.get_enterprises
  end

  def network_routers
    _network_routers.values
  end

  def cloud_networks_floating
    _shared_resources.select { |res| res['type'] == 'FLOATING' }
  end

  def cloud_subnets
    vsd_client.get_subnets
  end

  def l2_cloud_subnets
    return @l2_cloud_subnets if @l2_cloud_subnets.any?
    @l2_cloud_subnets = vsd_client.get_l2_domains
  end

  def security_groups
    vsd_client.get_policy_groups
  end

  def floating_ips
    vsd_client.get_floating_ips
  end

  def network_ports
    ports = network_routers.each_with_object([]) { |domain, res| res.concat(vsd_client.get_vports_for_domain(domain['ID'])) }
    ports.concat(l2_cloud_subnets.each_with_object([]) { |l2_domain, res| res.concat(vsd_client.get_vports_for_l2_domain(l2_domain['ID'])) })
    ports
  end

  def security_groups_for_network_port(port_ems_ref)
    vsd_client.get_policy_groups_for_vport(port_ems_ref)
  end

  def vm_interfaces_for_network_port(port_ems_ref)
    vsd_client.get_vm_interfaces_for_vport(port_ems_ref)
  end

  def vms_for_network_port(port_ems_ref)
    vsd_client.get_vms_for_vport(port_ems_ref)
  end

  def container_interfaces_for_network_port(port_ems_ref)
    vsd_client.get_container_interfaces_for_vport(port_ems_ref)
  end

  def host_interfaces_for_network_port(port_ems_ref)
    vsd_client.get_host_interfaces_for_vport(port_ems_ref)
  end

  def zone(ems_ref)
    _zones[ems_ref]
  end

  private

  def _zones
    return @zones if @zones.any?
    @zones = hash_by_id(vsd_client.get_zones)
  end

  def _network_routers
    return @network_routers if @network_routers.any?
    @network_routers = hash_by_id(vsd_client.get_domains)
  end

  def _shared_resources
    return @shared_resources if @shared_resources.any?
    @shared_resources = vsd_client.get_sharednetworkresources
  end

  def hash_by_id(list)
    list.map { |el| [el['ID'], el] }.to_h
  end
end
