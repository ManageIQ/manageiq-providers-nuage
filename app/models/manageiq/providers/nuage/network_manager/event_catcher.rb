class ManageIQ::Providers::Nuage::NetworkManager::EventCatcher < ::MiqEventCatcher
  require_nested :Runner

  def self.ems_class
    ManageIQ::Providers::Nuage::NetworkManager
  end

  def self.settings_name
    :event_catcher_nuage_network
  end
end
