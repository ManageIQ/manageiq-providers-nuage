class ManageIQ::Providers::Nuage::Inventory::Collector < ManagerRefresh::Inventory::Collector
  require_nested :NetworkManager
  require_nested :TargetCollection

  def initialize(_manager, _target)
    super

    initialize_inventory_sources
  end

  def initialize_inventory_sources
    @cloud_tenants    = {}
    @cloud_subnets    = []
    @l2_cloud_subnets = []
    @security_groups  = []
    @zones            = {}
    @network_routers  = {}
  end

  def vsd_client
    @vsd_client ||= manager.connect
  end
end
