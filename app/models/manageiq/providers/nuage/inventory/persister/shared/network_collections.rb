module ManageIQ::Providers::Nuage::Inventory::Persister::Shared::NetworkCollections
  extend ActiveSupport::Concern

  # TODO: move to core
  # Builder class for Network
  def network
    ::ManagerRefresh::InventoryCollection::Builder::NetworkManager
  end

  def initialize_network_inventory_collections
    %i(cloud_subnets
       security_groups
       network_groups).each do |name|

      add_collection(network, name) do |builder|
        builder.add_properties(:parent => manager) # including targeted
      end
    end
  end
end
