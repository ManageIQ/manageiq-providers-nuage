class ManageIQ::Providers::Nuage::Inventory::Persister < ManagerRefresh::Inventory::Persister
  require_nested :NetworkManager
  require_nested :TargetCollection

  protected

  def network
    ManageIQ::Providers::Nuage::InventoryCollectionDefault::NetworkManager
  end

  def targeted
    false
  end

  def strategy
    nil
  end

  def shared_options
    settings_options = options[:inventory_collections].try(:to_hash) || {}

    settings_options.merge(
      :strategy => strategy,
      :targeted => targeted,
    )
  end
end
