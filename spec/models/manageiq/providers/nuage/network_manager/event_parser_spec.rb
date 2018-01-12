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
          :event_type => 'subnet_create',
          :ems_ref    => '56e69f6e-a1fd-457f-b4c5-844cfd790153'
        }
      },
      {
        :name     => 'with null requestID',
        :fixture  => '/event_catcher/alarm_delete.json',
        :expected => {
          :event_type => 'alarm_delete',
          :ems_ref    => 'random-11111111-2222-3333-4444-555555555555'
        }
      },
      {
        :name     => 'with empty requestID',
        :fixture  => '/event_catcher/alarm_create.json',
        :expected => {
          :event_type => 'alarm_create',
          :ems_ref    => 'random-11111111-2222-3333-4444-555555555555'
        }
      }
    ].each do |example|
      it example[:name] do
        message = JSON.parse(File.read(File.join(__dir__, example[:fixture])))
        example[:expected][:ems_id] = ems.id
        example[:expected][:vm_ems_ref] = nil
        example[:expected][:source] = 'NUAGE'
        example[:expected][:message] = example[:expected][:event_type] if example[:expected][:event_type]
        example[:expected][:full_data] = message.to_hash
        expect(described_class.event_to_hash(message, ems.id)).to include(example[:expected])
      end
    end
  end
end
