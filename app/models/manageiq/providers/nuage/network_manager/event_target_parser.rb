class ManageIQ::Providers::Nuage::NetworkManager::EventTargetParser
  attr_reader :ems_event

  # @param ems_event [EmsEvent] EmsEvent object
  def initialize(ems_event)
    @ems_event = ems_event
  end

  # Parses all targets that are present in the EmsEvent given in the initializer
  #
  # @return [Array] Array of ManagerRefresh::Target objects
  def parse
    parse_ems_event_targets(ems_event)
  end

  private

  # Parses list of ManagerRefresh::Target out of the given EmsEvent
  #
  # @param event [EmsEvent] EmsEvent object
  # @return [Array] Array of ManagerRefresh::Target objects
  def parse_ems_event_targets(event)
    target_collection = ManagerRefresh::TargetCollection.new(:manager => event.ext_management_system, :event => event)

    $nuage_log.debug(
      [
        'target:', event.full_data['entityType'], '-', event.full_data['type'], '-',
        event.full_data['entities'][0]['name'], '-', event.full_data['entities'][0]['ID']
      ].join(' ')
    )

    case event.full_data["entityType"]
    when 'enterprise'
      add_targets(target_collection, :cloud_tenants, event.full_data['entities'])
    when 'subnet'
      add_targets(target_collection, :cloud_subnets, event.full_data['entities'], :options => { :kind => 'L3' })
    when 'l2domain'
      add_targets(target_collection, :cloud_subnets, event.full_data['entities'], :options => { :kind => 'L2' })
    when 'policygroup'
      add_targets(target_collection, :security_groups, event.full_data['entities'])
    when 'domain'
      add_targets(target_collection, :network_routers, event.full_data['entities'],
                  :options => { :operation => event.full_data['type'].to_s.upcase })
    when 'sharednetworkresource'
      add_targets(target_collection, :cloud_networks, event.full_data['entities'])
    when 'floatingip'
      add_targets(target_collection, :floating_ips, event.full_data['entities'])
    when 'vport'
      add_targets(target_collection, :network_ports, event.full_data['entities'])
    end

    target_collection.targets
  end

  def add_targets(target_collection, association, entities, key: 'ID', options: {})
    return unless entities.respond_to?(:each)
    entities.each do |obj|
      next if obj[key].to_s.empty?
      target_collection.add_target(:association => association, :manager_ref => {:ems_ref => obj[key]}, :options => options)
    end
  end
end
