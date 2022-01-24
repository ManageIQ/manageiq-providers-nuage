class ManageIQ::Providers::Nuage::Inventory::Parser::NetworkManager < ManageIQ::Providers::Nuage::Inventory::Parser
  def parse
    cloud_tenants
    cloud_networks_floating
    network_routers
    cloud_subnets
    l2_cloud_subnets
    security_groups
    floating_ips
    network_ports
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

  def cloud_networks_floating
    collector.cloud_networks_floating.each do |network|
      persister.cloud_networks.find_or_build(network['ID']).assign_attributes(
        :type => collector.manager.class.floating_cloud_network_type,
        :name => network['name'],
        :cidr => to_cidr(network['address'], network['netmask'])
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
      extra['template_id'] = subnet['templateID']
      persister.cloud_subnets.find_or_build(subnet['ID']).assign_attributes(
        :type             => collector.manager.class.l3_cloud_subnet_type,
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

  def l2_cloud_subnets
    collector.l2_cloud_subnets.each do |subnet|
      persister.cloud_subnets.find_or_build(subnet['ID']).assign_attributes(
        :type             => collector.manager.class.l2_cloud_subnet_type,
        :name             => subnet['name'],
        :cidr             => to_cidr(subnet['address'], subnet['netmask']),
        :network_protocol => subnet['IPType'].to_s.downcase,
        :cloud_tenant     => persister.cloud_tenants.lazy_find(subnet['parentID'])
      )
    end
  end

  def security_groups
    collector.security_groups.each do |sg|
      group = persister.security_groups.find_or_build(sg['ID']).assign_attributes(
        :name => sg['name']
      )

      if sg['parentType'] == 'domain' # Security group on L3 domain.
        group.network_router = persister.network_routers.lazy_find(sg['parentID'])
        group.cloud_tenant = persister.network_routers.lazy_find(sg['parentID'], :key => :cloud_tenant)
      else # Security group on L2 domain.
        group.cloud_subnet = persister.cloud_subnets.lazy_find(sg['parentID'])
        group.cloud_tenant = persister.cloud_subnets.lazy_find(sg['parentID'], :key => :cloud_tenant)
      end
    end
  end

  def floating_ips
    collector.floating_ips.each do |ip|
      persister.floating_ips.find_or_build(ip['ID']).assign_attributes(
        :address        => ip['address'],
        :cloud_network  => persister.cloud_networks.lazy_find(ip['associatedSharedNetworkResourceID']),
        :network_router => persister.network_routers.lazy_find(ip['parentID']),
        :cloud_tenant   => persister.network_routers.lazy_find(ip['parentID'], :key => :cloud_tenant)
      )
    end
  end

  def network_ports
    collector.network_ports.each do |port|
      network_port = persister.network_ports.find_or_build(port['ID']).assign_attributes(
        :name            => port['name'],
        :floating_ip     => persister.floating_ips.lazy_find(port['associatedFloatingIPID']),
        :security_groups => collector.security_groups_for_network_port(port['ID']).map { |sg| persister.security_groups.lazy_find(sg['ID']) },
        :cloud_tenant    => persister.cloud_subnets.lazy_find(port['parentID'], :key => :cloud_tenant)
      )

      # Type-specific properties.
      case port['type'].to_s.upcase
      when 'BRIDGE'
        network_port_type = collector.manager.class.bridge_network_port_type
        address           = nil
        vm_ref            = nil
      when 'CONTAINER'
        network_port_type = collector.manager.class.container_network_port_type
        address           = first_ip_address(collector.container_interfaces_for_network_port(port['ID']))
        vm_ref            = nil
      when 'HOST'
        network_port_type = collector.manager.class.host_network_port_type
        address           = first_ip_address(collector.host_interfaces_for_network_port(port['ID']))
        vm_ref            = nil
      when 'VM'
        network_port_type = collector.manager.class.vm_network_port_type
        address           = first_ip_address(collector.vm_interfaces_for_network_port(port['ID']))
        vm_ref            = first_vm_uuid(collector.vms_for_network_port(port['ID']))
      else
        network_port_type = 'ManageIQ::Providers::Nuage::NetworkManager::NetworkPort'
        address           = nil
        vm_ref            = nil
      end

      network_port.type = network_port_type
      network_port.device = persister.cross_link_vms.lazy_find({:uid_ems => vm_ref}, {:ref => :by_uid_ems}) if vm_ref
      network_port.cloud_subnet_network_ports = [
        persister.cloud_subnet_network_ports.find_or_build_by(
          :cloud_subnet => persister.cloud_subnets.lazy_find(port['parentID']),
          :address      => address,
          :network_port => network_port
        )
      ]
    end
  end

  def map_extra_attributes(zone_id)
    if (zone = collector.zone(zone_id))
      {
        'domain_id'        => zone['parentID'],
        'zone_name'        => zone['name'],
        'zone_id'          => zone_id,
        'zone_template_id' => zone['templateID']
      }
    else
      {}
    end
  end

  def to_cidr(address, netmask)
    return unless address && netmask
    address.to_s + '/' + netmask.to_s.split(".").map { |e| e.to_i.to_s(2).rjust(8, "0") }.join.count("1").to_s
  end

  def first_ip_address(interfaces)
    (interfaces.first || {}).dig('IPAddress')
  end

  def first_vm_uuid(vms)
    (vms.first || {}).dig('UUID')
  end
end
