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

  context '.auth_url' do
    it 'builds insecure URL' do
      expect(described_class.auth_url(nil, 'hostname', 8443, 'v5')).to eq('http://hostname:8443/nuage/api/v5')
    end

    it 'builds secure URL' do
      expect(described_class.auth_url('ssl-with-validation', 'hostname', 8443, 'v5')).to eq('https://hostname:8443/nuage/api/v5')
    end

    it 'builds correct IPv6 URL' do
      expect(described_class.auth_url('ssl-with-validation', '::1', 8443, 'v5')).to eq('https://[::1]:8443/nuage/api/v5')
    end
  end
end
