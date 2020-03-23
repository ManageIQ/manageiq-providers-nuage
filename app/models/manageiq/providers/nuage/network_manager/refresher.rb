module ManageIQ::Providers
  class Nuage::NetworkManager::Refresher < ManageIQ::Providers::BaseManager::Refresher
    def post_process_refresh_classes
      []
    end
  end
end
