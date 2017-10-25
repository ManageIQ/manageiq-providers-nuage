describe ManageIQ::Providers::Nuage::NetworkManager do
  it '.ems_type' do
    expect(described_class.ems_type).to eq('nuage_network')
  end

  it '.description' do
    expect(described_class.description).to eq('Nuage Network Manager')
  end

  context 'validation' do
    before :each do
      @ems = FactoryGirl.create(:ems_nuage_network_with_authentication)
    end

    it 'raises error for unsupported auth type' do
      creds = {}
      creds[:unsupported] = {:userid => "unsupported", :password => "password"}
      @ems.endpoints << Endpoint.create(:role => 'unsupported', :hostname => 'hostname', :port => 1111)
      @ems.update_authentication(creds, :save => false)
      expect do
        @ems.verify_credentials(:unsupported)
      end.to raise_error(MiqException::MiqInvalidCredentialsError)
    end
  end
end
