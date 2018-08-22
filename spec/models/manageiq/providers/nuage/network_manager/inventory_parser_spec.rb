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

    let(:collector) { double('collector', :zone => zone) }
    let(:zone)      { {} }

    context 'when zone not found' do
      let(:zone) { nil }
      it 'invoke' do
        expect(subject.send(:map_extra_attributes, 'the-zone')).to eq({})
      end
    end

    context 'regular case' do
      let(:zone) { { 'name' => 'Zone Name', 'parentID' => 'domain-id', 'templateID' => 'template-id' } }
      it 'invoke' do
        expect(subject.send(:map_extra_attributes, 'the-zone')).to eq(
          'domain_id'        => 'domain-id',
          'zone_name'        => 'Zone Name',
          'zone_id'          => 'the-zone',
          'zone_template_id' => 'template-id'
        )
      end
    end
  end
end
