module ManageIQ::Providers::Nuage::NetworkManager::EventParser
  def self.event_to_hash(event, ems_id)
    event_type = "#{event['entityType']}_#{event['type'].downcase}"
    {
      :source     => "NUAGE",
      :event_type => event_type,
      :timestamp  => DateTime.strptime((event["eventReceivedTime"] / 1000).to_s, '%s').to_s,
      :message    => event_type,
      :vm_ems_ref => nil,
      :full_data  => event.to_hash,
      :ems_id     => ems_id
    }
  end
end
