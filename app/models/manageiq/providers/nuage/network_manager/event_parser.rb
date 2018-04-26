module ManageIQ::Providers::Nuage::NetworkManager::EventParser
  def self.event_to_hash(event, ems_id)
    entity = event.dig('entities', 0) || {}

    case event['entityType']
    when 'alarm'
      type       = entity['alarmedObjectType'] || entity['targetObject']
      event_type = "nuage_alarm_#{type}_#{event['type']}_#{entity['errorCondition']}"
      message    = "#{entity['severity']}: #{entity['reason']}"
    else
      event_type = "nuage_#{event['entityType']}_#{event['type']}"
      message    = "#{entity['name']} (#{entity['ID']})"
    end

    {
      :source     => "NUAGE",
      :event_type => event_type.downcase,
      :timestamp  => DateTime.strptime((event["eventReceivedTime"] / 1000).to_s, '%s').to_s,
      :message    => message,
      :vm_ems_ref => nil,
      :full_data  => event.to_hash,
      :ems_id     => ems_id,
      :ems_ref    => event["requestID"].presence || "random-#{SecureRandom.uuid}"
    }
  end
end
