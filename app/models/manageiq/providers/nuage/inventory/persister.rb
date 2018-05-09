class ManageIQ::Providers::Nuage::Inventory::Persister < ManagerRefresh::Inventory::Persister
  require_nested :NetworkManager
  require_nested :TargetCollection

  protected

  def strategy
    nil
  end

  def shared_options
    {
      :strategy => strategy,
      :targeted => targeted?,
    }
  end
end
