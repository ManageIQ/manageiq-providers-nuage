class ManageIQ::Providers::Nuage::Inventory::Persister::TargetCollection < ManageIQ::Providers::Nuage::Inventory::Persister
  include ManageIQ::Providers::Nuage::Inventory::Persister::Shared::NetworkCollections

  def initialize_inventory_collections
    initialize_network_inventory_collections
  end

  protected

  def targeted?
    true
  end

  def strategy
    :local_db_find_missing_references
  end
end
