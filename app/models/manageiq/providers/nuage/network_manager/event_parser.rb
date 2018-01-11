module ManageIQ::Providers::Nuage::NetworkManager::EventParser
  def self.event_to_hash(event, ems_id)
    event_type = "#{event['entityType']}_#{event['type'].downcase}"
    # Nuage pushes several events with the same eventReceivedTime causing
    # EmsEvent to ignore some of them because of the same primary key. Here we
    # just add several millisecconds to the event.
    time = event["eventReceivedTime"] + Time.now.usec / 1000
    {
      :source     => "NUAGE",
      :event_type => event_type,
      :timestamp  => DateTime.strptime(time.to_s, '%Q').strftime('%F %T.%6N'),
      :message    => event_type,
      :vm_ems_ref => nil,
      :full_data  => event.to_hash,
      :ems_id     => ems_id
    }
  end
end
