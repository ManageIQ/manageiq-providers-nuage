class ManageIQ::Providers::Nuage::NetworkManager::RefreshWorker < ManageIQ::Providers::BaseManager::RefreshWorker
  require_nested :Runner

  def self.settings_name
    :ems_refresh_worker_nuage_network
  end
end
