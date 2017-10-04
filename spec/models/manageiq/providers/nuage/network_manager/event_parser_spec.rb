describe ManageIQ::Providers::Nuage::NetworkManager::EventParser do
  context ".event_to_hash" do
    it "parses vm_ems_ref into event" do
      ems = FactoryGirl.create(:ems_nuage_network)
      message = JSON.parse(File.read(File.join(__dir__, "/event_catcher/alarm_delete.json")))

      expect(described_class.event_to_hash(message, ems)).to include(
        :source     => "NUAGE",
        :vm_ems_ref => nil,
        :event_type => 'alarm_delete',
        :ems_id     => ems
      )
    end
  end
end
