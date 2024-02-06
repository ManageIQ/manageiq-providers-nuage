class ManageIQ::Providers::Nuage::NetworkManager::RefreshWorker < ManageIQ::Providers::BaseManager::RefreshWorker
  def self.settings_name
    :ems_refresh_worker_nuage_network
  end
end
