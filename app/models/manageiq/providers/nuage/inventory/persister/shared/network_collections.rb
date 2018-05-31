module ManageIQ::Providers::Nuage::Inventory::Persister::Shared::NetworkCollections
  extend ActiveSupport::Concern

  def initialize_network_inventory_collections
    %i(cloud_tenants
       cloud_subnets
       security_groups
       network_routers).each do |name|

      add_collection(network, name) do |builder|
        builder.add_properties(:parent => manager) # including targeted
      end
    end
  end
end
