module ManageIQ::Providers
  class Nuage::NetworkManager::Refresher < ManageIQ::Providers::BaseManager::ManagerRefresher
    def parse_legacy_inventory(_ems)
      raise NotImplementedError, 'legacy refresh is no longer supported'
    end

    def post_process_refresh_classes
      []
    end
  end
end
