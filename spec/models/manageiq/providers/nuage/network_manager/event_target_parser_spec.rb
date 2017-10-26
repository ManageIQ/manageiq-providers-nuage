describe ManageIQ::Providers::Nuage::NetworkManager::EventTargetParser do
  before :each do
    _guid, _server, zone = EvmSpecHelper.create_guid_miq_server_zone
    @ems                 = FactoryGirl.create(:ems_nuage_network, :zone => zone)

    allow_any_instance_of(EmsEvent).to receive(:handle_event)
    allow(EmsEvent).to receive(:create_completed_event)
  end

  context "Events trigger targeted refresh" do
    it "entityType: enterprise" do
      assert_event_triggers_target(
        'enterprise_create.json',
        [[:network_groups, {:ems_ref => 'fda58efc-7f7c-4a51-b6b4-24b32d755785'}]]
      )
    end

    it "entityType: subnet" do
      assert_event_triggers_target(
        'subnet_create.json',
        [[:cloud_subnets, {:ems_ref => '4e08bf9c-b679-4c82-a6f7-b298a3901d25'}]]
      )
    end

    it "entityType: policygroup" do
      assert_event_triggers_target(
        'policygroup_create.json',
        [[:security_groups, {:ems_ref => 'fadd09c4-9fea-46ec-8342-73f1b6a4df74'}]]
      )
    end

    it "entityType: domain" do
      assert_event_triggers_target(
        'domain_create.json',
        [[:network_groups, {:ems_ref => 'fda58efc-7f7c-4a51-b6b4-24b32d755785'}]]
      )
    end
  end

  context "Alarms don't trigger targeted refresh" do
    it "alarm" do
      assert_event_triggers_target('alarm_create.json', [])
    end
  end

  def assert_event_triggers_target(event_data, expected_targets)
    ems_event      = create_ems_event(event_data)
    parsed_targets = described_class.new(ems_event).parse

    expect(parsed_targets.size).to eq(expected_targets.count)
    expect(target_references(parsed_targets)).to(
      match_array(expected_targets)
    )
  end

  def target_references(parsed_targets)
    parsed_targets.map { |x| [x.association, x.manager_ref] }.uniq
  end

  def response(path)
    JSON.parse(File.read(File.join(File.dirname(__FILE__), "/event_catcher/#{path}")))
  end

  def create_ems_event(path)
    event_hash = ManageIQ::Providers::Nuage::NetworkManager::EventParser.event_to_hash(response(path), @ems.id)
    EmsEvent.add(@ems.id, event_hash)
  end
end
