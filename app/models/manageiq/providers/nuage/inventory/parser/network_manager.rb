class ManageIQ::Providers::Nuage::Inventory::Parser::NetworkManager < ManageIQ::Providers::Nuage::Inventory::Parser
  def parse
    cloud_tenants
    network_routers
    cloud_subnets
    security_groups
  end

  private

  def cloud_tenants
    collector.cloud_tenants.each do |enterprise|
      persister.cloud_tenants.find_or_build(enterprise['ID']).assign_attributes(
        :name        => enterprise['name'],
        :description => enterprise['description']
      )
    end
  end

  def network_routers
    collector.network_routers.each do |router|
      persister.network_routers.find_or_build(router['ID']).assign_attributes(
        :name         => router['name'],
        :cloud_tenant => persister.cloud_tenants.lazy_find(router['parentID'])
      )
    end
  end

  def cloud_subnets
    collector.cloud_subnets.each do |subnet|
      extra = map_extra_attributes(subnet['parentID']) || {}
      persister.cloud_subnets.find_or_build(subnet['ID']).assign_attributes(
        :name             => subnet['name'],
        :cidr             => to_cidr(subnet['address'], subnet['netmask']),
        :network_protocol => subnet['IPType'].downcase,
        :gateway          => subnet['gateway'],
        :dhcp_enabled     => false,
        :extra_attributes => extra,
        :cloud_tenant     => persister.network_routers.lazy_find(extra['domain_id'], :key => :cloud_tenant),
        :network_router   => persister.network_routers.lazy_find(extra['domain_id']),
      )
    end
  end

  def security_groups
    collector.security_groups.each do |sg|
      persister.security_groups.find_or_build(sg['ID']).assign_attributes(
        :name         => sg['name'],
        :cloud_tenant => persister.network_routers.lazy_find(sg['parentID'], :key => :cloud_tenant)
      )
    end
  end

  def map_extra_attributes(zone_id)
    if (zone = collector.zone(zone_id))
      {
        'domain_id' => zone['parentID'],
        'zone_name' => zone['name'],
        'zone_id'   => zone_id
      }
    else
      {}
    end
  end

  def to_cidr(address, netmask)
    return unless address && netmask
    address.to_s + '/' + netmask.to_s.split(".").map { |e| e.to_i.to_s(2).rjust(8, "0") }.join.count("1").to_s
  end
end
