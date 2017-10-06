class ManageIQ::Providers::Nuage::Inventory::Persister::NetworkManager < ManageIQ::Providers::Nuage::Inventory::Persister
  def initialize_inventory_collections
    add_inventory_collections(
      network,
      %i(cloud_subnets security_groups network_groups)
    )
  end
end
