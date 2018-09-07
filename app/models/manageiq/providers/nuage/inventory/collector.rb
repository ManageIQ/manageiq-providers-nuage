class ManageIQ::Providers::Nuage::Inventory::Collector < ManageIQ::Providers::Inventory::Collector
  require_nested :NetworkManager
  require_nested :TargetCollection

  def initialize(_manager, _target)
    super

    initialize_inventory_sources
  end

  def initialize_inventory_sources
    @l2_cloud_subnets = []
    @zones            = {}
    @network_routers  = {}
    @shared_resources = []
  end

  def vsd_client
    @vsd_client ||= manager.connect
  end
end
