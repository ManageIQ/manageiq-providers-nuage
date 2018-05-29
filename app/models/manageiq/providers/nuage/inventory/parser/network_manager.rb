class ManageIQ::Providers::Nuage::Inventory::Parser::NetworkManager < ManageIQ::Providers::Nuage::Inventory::Parser
  def parse
    cloud_tenants
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
        :cloud_tenant     => persister.cloud_tenants.lazy_find(extra["enterprise_id"])
      )
    end
  end

  def security_groups
    collector.security_groups.each do |sg|
      domain_id = sg['parentID']
      domain = collector.domain(domain_id) || {}

      persister.security_groups.find_or_build(sg['ID']).assign_attributes(
        :name         => sg['name'],
        :cloud_tenant => persister.cloud_tenants.lazy_find(domain['parentID'])
      )
    end
  end

  def map_extra_attributes(zone_id)
    zone = collector.zone(zone_id)
    return unless zone
    domain_id = zone['parentID']
    domain = collector.domain(domain_id)
    return unless domain
    tenant_id = domain['parentID']
    tenant = collector.cloud_tenant(tenant_id)
    return unless tenant

    {
      "enterprise_name" => tenant['name'],
      "enterprise_id"   => domain['parentID'],
      "domain_name"     => domain['name'],
      "domain_id"       => domain_id,
      "zone_name"       => zone['name'],
      "zone_id"         => zone_id
    }
  end

  def to_cidr(address, netmask)
    return unless address && netmask
    address.to_s + '/' + netmask.to_s.split(".").map { |e| e.to_i.to_s(2).rjust(8, "0") }.join.count("1").to_s
  end
end
