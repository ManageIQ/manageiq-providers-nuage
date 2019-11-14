class ManageIQ::Providers::Nuage::NetworkManager::EventCatcher < ::MiqEventCatcher
  require_nested :Runner

  def self.settings_name
    :event_catcher_nuage_network
  end

  def self.all_valid_ems_in_zone
    # Only run event catcher for those Nuage providers that have credentials for it.
    # NOTE: ATM it's safest to check if hostname is non-empty string because
    # frontend seems to be inserting empty Authentication and Endpoint even
    # if user opts-in for "None" in AMQP tab.
    super.select do |ems|
      ems.endpoints.any? { |e| e.role == 'amqp' && e.hostname.present? }
    end
  end
end
