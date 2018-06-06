class ManageIQ::Providers::Nuage::Inventory::Collector::NetworkManager < ManageIQ::Providers::Nuage::Inventory::Collector
  def cloud_tenants
    _cloud_tenants.values
  end

  def network_routers
    _network_routers.values
  end

  def cloud_subnets
    return @cloud_subnets if @cloud_subnets.any?
    @cloud_subnets = vsd_client.get_subnets
  end

  def l2_cloud_subnets
    return @l2_cloud_subnets if @l2_cloud_subnets.any?
    @l2_cloud_subnets = vsd_client.get_l2_domains
  end

  def security_groups
    return @security_groups if @security_groups.any?
    @security_groups = vsd_client.get_policy_groups
  end

  def zones
    _zones.values
  end

  def security_group(ems_ref)
    security_groups.find { |sg| sg['ID'] == ems_ref }
  end

  def cloud_tenant(ems_ref)
    _cloud_tenants[ems_ref]
  end

  def zone(ems_ref)
    _zones[ems_ref]
  end

  def network_router(ems_ref)
    _network_routers[ems_ref]
  end

  private

  def _cloud_tenants
    return @cloud_tenants if @cloud_tenants.any?
    @cloud_tenants = hash_by_id(vsd_client.get_enterprises)
  end

  def _zones
    return @zones if @zones.any?
    @zones = hash_by_id(vsd_client.get_zones)
  end

  def _network_routers
    return @network_routers if @network_routers.any?
    @network_routers = hash_by_id(vsd_client.get_domains)
  end

  def hash_by_id(list)
    list.map { |el| [el['ID'], el] }.to_h
  end
end
