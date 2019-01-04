describe ManageIQ::Providers::Nuage::NetworkManager::EventCatcher::Runner do
  before do
    allow_any_instance_of(described_class).to receive_messages(:worker_initialization => nil, :after_initialize => nil)
    allow(subject).to receive(:worker_settings).and_return({})
    subject.instance_variable_set(:@ems, ems)
  end

  let(:ems)    { FactoryBot.create(:ems_nuage_network_with_authentication) }
  let(:handle) { double('handle', :start => nil) }

  it '.event_monitor_handle' do
    expect(subject.event_monitor_handle).not_to be_nil
  end

  it '.monitor_events' do
    allow(subject).to receive(:event_monitor_handle).and_return(handle)
    expect { subject.monitor_events }.not_to raise_error
  end
end
