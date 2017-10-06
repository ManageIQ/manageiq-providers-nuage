class ManageIQ::Providers::Nuage::Inventory::Collector::NetworkManager < ManageIQ::Providers::Nuage::Inventory::Collector
  def cloud_subnets
    return @cloud_subnets if @cloud_subnets.any?
    @cloud_subnets = vsd_client.get_subnets
  end

  def security_groups
    return @security_groups if @security_groups.any?
    @security_groups = vsd_client.get_policy_groups
  end

  def network_groups
    return @network_groups if @network_groups.any?
    @network_groups = vsd_client.get_enterprises
  end

  def zones
    return @zones if @zones.any?
    @zones = vsd_client.get_zones.map { |zone| [zone['ID'], zone] } .to_h
  end

  def domains
    return @domains if @domains.any?
    @domains = vsd_client.get_domains.map { |domain| [domain['ID'], domain] } .to_h
  end
end
