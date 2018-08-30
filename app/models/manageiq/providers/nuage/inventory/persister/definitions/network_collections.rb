module ManageIQ::Providers::Nuage::Inventory::Persister::Definitions::NetworkCollections
  extend ActiveSupport::Concern

  def initialize_network_inventory_collections
    %i(cloud_tenants
       cloud_subnets
       security_groups
       cloud_networks
       floating_ips
       network_ports
       network_routers).each do |name|

      add_collection(network, name) do |builder|
        builder.add_properties(:parent => manager) # including targeted
      end
    end

    add_cloud_subnet_network_ports
    add_cross_provider_vms
  end

  def add_cloud_subnet_network_ports(extra_properties = {})
    add_collection(network, :cloud_subnet_network_ports, extra_properties) do |builder|
      builder.add_properties(:manager_ref_allowed_nil => %i(cloud_subnet))
      builder.add_properties(:parent => manager, :parent_inventory_collections => %i(network_ports))
    end
  end

  def add_cross_provider_vms
    add_collection(cloud, :vms) do |builder|
      builder.add_properties(
        :arel        => Vm.all,
        :strategy    => :local_db_find_references,
        :association => nil
      )
    end
  end
end
