class ManageIQ::Providers::Nuage::Inventory::Parser::NetworkManager < ManageIQ::Providers::Nuage::Inventory::Parser
  def parse
    cloud_subnets
    security_groups
    network_groups
  end

  private

  def cloud_subnets
    collector.cloud_subnets.each do |subnet|
      extra = map_extra_attributes(subnet['parentID'])
      persister.cloud_subnets.find_or_build(subnet['ID']).assign_attributes(
        :name             => subnet['name'],
        :cidr             => to_cidr(subnet['address'], subnet['netmask']),
        :network_protocol => subnet['IPType'].downcase,
        :gateway          => subnet['gateway'],
        :dhcp_enabled     => false,
        :extra_attributes => extra,
        :network_group    => persister.network_groups.lazy_find(extra["enterprise_id"])
      )
    end
  end

  def security_groups
    collector.security_groups.each do |sg|
      sec_group = persister.security_groups.find_or_build(sg['ID']).assign_attributes(
        :name => sg['name']
      )

      # On G-branch we're only able to inventory domains ('L3 domains') so we cannot
      # fetch parent if it's of any other type (like 'L2 domain') in order to inventory
      # 'SecurityGroup belongs to NetworkGroup' relation. The issue is fixed on H-branch,
      # but is not ported to G since NetworkGroup model has been replaced with CloudTenant.
      if sg['parentType'] == 'domain' && (domain = collector.domain(sg['parentID']))
        sec_group.network_group = persister.network_groups.lazy_find(domain['parentID'])
      end
    end
  end

  def network_groups
    collector.network_groups.each do |ng|
      persister.network_groups.find_or_build(ng['ID']).assign_attributes(
        :name   => ng['name'],
        :status => 'active'
      )
    end
  end

  def map_extra_attributes(zone_id)
    zone = collector.zone(zone_id)
    domain_id = zone['parentID']
    domain = collector.domain(domain_id)
    network_group_id = domain['parentID']
    network_group = collector.network_group(network_group_id)

    {
      "enterprise_name" => network_group['name'],
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
