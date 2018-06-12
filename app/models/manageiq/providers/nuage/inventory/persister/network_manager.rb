class ManageIQ::Providers::Nuage::Inventory::Persister::NetworkManager < ManageIQ::Providers::Nuage::Inventory::Persister
  include ManageIQ::Providers::Nuage::Inventory::Persister::Definitions::NetworkCollections

  def initialize_inventory_collections
    initialize_network_inventory_collections
  end
end
