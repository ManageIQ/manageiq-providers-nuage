describe ManageIQ::Providers::Nuage::NetworkManager::EventParser do
  before do
    allow(SecureRandom).to receive(:uuid).and_return('11111111-2222-3333-4444-555555555555')
  end

  let(:ems) { FactoryGirl.create(:ems_nuage_network) }

  context ".event_to_hash" do
    [
      {
        :name     => 'with requestID',
        :fixture  => '/event_catcher/subnet_create.json',
        :expected => {
          :event_type => 'nuage_subnet_create',
          :message    => 'Audit-Subnet (4e08bf9c-b679-4c82-a6f7-b298a3901d25)',
          :ems_ref    => '56e69f6e-a1fd-457f-b4c5-844cfd790153'
        }
      },
      {
        :name     => 'with null requestID',
        :fixture  => '/event_catcher/alarm_delete.json',
        :expected => {
          :event_type => 'nuage_alarm_nsgateway_delete_4707',
          :message    => 'MAJOR: Gateway with system-id [201.26.92.41] is disconnected',
          :ems_ref    => 'random-11111111-2222-3333-4444-555555555555'
        }
      },
      {
        :name     => 'with empty requestID',
        :fixture  => '/event_catcher/alarm_create.json',
        :expected => {
          :event_type => 'nuage_alarm_nsgateway_create_4707',
          :message    => 'MAJOR: Gateway with system-id [213.50.60.102] is disconnected',
          :ems_ref    => 'random-11111111-2222-3333-4444-555555555555'
        }
      },
      {
        :name     => 'alarm 4713',
        :fixture  => '/event_catcher/alarm_4713.json',
        :expected => {
          :event_type => 'nuage_alarm_nsgateway_delete_4713',
          :message    => 'MAJOR: Gateway with system-id [213.50.60.102] is disconnected from controller [vsc1:100.100.100.21]',
          :ems_ref    => 'random-11111111-2222-3333-4444-555555555555'
        }
      }
    ].each do |example|
      it example[:name] do
        message = JSON.parse(File.read(File.join(__dir__, example[:fixture])))
        example[:expected][:ems_id] = ems.id
        example[:expected][:vm_ems_ref] = nil
        example[:expected][:source] = 'NUAGE'
        example[:expected][:message] = example[:expected][:message]
        example[:expected][:full_data] = message.to_hash
        expect(described_class.event_to_hash(message, ems.id)).to include(example[:expected])
      end
    end
  end
end
