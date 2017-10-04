describe ManageIQ::Providers::Nuage::NetworkManager::EventCatcher do
  it '.ems_class' do
    expect(described_class.ems_class).to eq(ManageIQ::Providers::Nuage::NetworkManager)
  end

  it 'settings_name' do
    expect(described_class.settings_name).to eq(:event_catcher_nuage_network)
  end
end
