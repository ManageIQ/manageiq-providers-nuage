describe ManageIQ::Providers::Nuage::Inventory::Parser::NetworkManager do
  describe '.to_cidr' do
    it 'normal' do
      expect(subject.send(:to_cidr, '192.168.0.0', '255.255.255.0')).to eq('192.168.0.0/24')
    end

    it 'address and netmask nil' do
      expect(subject.send(:to_cidr, nil, nil)).to be_nil
    end
  end

  describe '.map_extra_attributes' do
    before(:each) do
      allow(subject).to receive(:collector).and_return(collector)
    end

    let(:collector)     { double('collector', :zone => zone, :domain => domain, :network_group => network_group) }
    let(:zone)          { {} }
    let(:domain)        { {} }
    let(:network_group) { {} }

    context 'when zone not found' do
      let(:zone) { nil }
      it 'invoke' do
        expect(subject.send(:map_extra_attributes, 'the-zone')).to eq(nil)
      end
    end

    context 'when domain not found' do
      let(:domain) { nil }
      it 'invoke' do
        expect(subject.send(:map_extra_attributes, 'the-zone')).to eq(nil)
      end
    end

    context 'when network group not found' do
      let(:network_group) { nil }
      it 'invoke' do
        expect(subject.send(:map_extra_attributes, 'the-zone')).to eq(nil)
      end
    end

    context 'regular case' do
      let(:zone)          { { 'name' => 'Zone Name', 'parentID' => 'domain-id' } }
      let(:domain)        { { 'name' => 'Domain Name', 'parentID' => 'network-group-id' } }
      let(:network_group) { { 'name' => 'Network Group Name' } }
      it 'invoke' do
        expect(subject.send(:map_extra_attributes, 'the-zone')).to eq(
          'enterprise_name' => 'Network Group Name',
          'enterprise_id'   => 'network-group-id',
          'domain_name'     => 'Domain Name',
          'domain_id'       => 'domain-id',
          'zone_name'       => 'Zone Name',
          'zone_id'         => 'the-zone'
        )
      end
    end
  end

  describe '.cloud_subnets' do
    before do
      allow(subject).to receive_message_chain(:collector, :cloud_subnets).and_return([subnet])
      allow(subject).to receive(:map_extra_attributes).and_return(nil)
      allow(subject).to receive(:persister).and_return(persister)
    end

    let(:persister) { double('persister') }
    let(:subnet)    { { 'name' => 'Subnet Name', 'IPType' => 'ip-type' } }

    it 'map_extra_attributes returns nothing' do
      expect(persister).to receive_message_chain(:cloud_subnets, :find_or_build, :assign_attributes).with(hash_including(:extra_attributes => {}))
      expect(persister).to receive_message_chain(:network_groups, :lazy_find).with(nil)
      subject.send(:cloud_subnets)
    end
  end

  describe '.security_groups' do
    before do
      allow(subject).to receive(:collector).and_return(collector)
      allow(subject).to receive(:persister).and_return(persister)
    end

    let(:persister) { double('persister') }
    let(:collector) { double('collector', :domain => nil, :security_groups => [{}]) }

    it 'domain not found' do
      expect(persister).to receive_message_chain(:security_groups, :find_or_build, :assign_attributes).with(hash_including(:network_group => nil))
      expect(persister).to receive_message_chain(:network_groups, :lazy_find).with(nil)
      subject.send(:security_groups)
    end
  end
end
