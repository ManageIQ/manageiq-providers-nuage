class ManageIQ::Providers::Nuage::Inventory::Persister < ManagerRefresh::Inventory::Persister
  require_nested :NetworkManager
  require_nested :TargetCollection

  protected

  def strategy
    nil
  end

  def parent
    manager.presence
  end

  # Shared properties for inventory collections
  def shared_options
    {
      :parent   => parent,
      :strategy => strategy,
      :targeted => targeted?,
    }
  end
end
