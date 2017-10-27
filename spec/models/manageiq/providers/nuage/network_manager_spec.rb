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

  context '#event_monitor_options' do
    before(:each) do
      @ems = FactoryGirl.build(:ems_nuage_network, :hostname => "host", :ipaddress => "::1")
      @creds = {:amqp => {:userid => "amqp_user", :password => "amqp_pass"}}
      @ems.endpoints << Endpoint.create(:role => 'amqp', :hostname => 'amqp_hostname', :port => '5672')
      @ems.update_authentication(@creds, :save => false)
    end

    it 'returns options with a single endpoint' do
      opts = @ems.event_monitor_options

      expect(opts).to have_attributes(:urls => ['amqp_user:amqp_pass@amqp_hostname:5672'])
    end

    it 'returns options with a fallback URLs' do
      @ems.endpoints << Endpoint.create(:role => 'amqp_fallback1', :hostname => 'amqp_hostname1', :port => '5672')
      @ems.endpoints << Endpoint.create(:role => 'amqp_fallback2', :hostname => 'amqp_hostname2', :port => '5672')

      opts = @ems.event_monitor_options

      expect(opts[:urls]).to include('amqp_user:amqp_pass@amqp_hostname:5672',
                                     'amqp_user:amqp_pass@amqp_hostname1:5672',
                                     'amqp_user:amqp_pass@amqp_hostname2:5672')
    end
  end
end
