describe ManageIQ::Providers::Nuage::NetworkManager do
  it '.ems_type' do
    expect(described_class.ems_type).to eq('nuage_network')
  end

  it '.description' do
    expect(described_class.description).to eq('Nuage Network Manager')
  end

  describe '.api_version_valid?' do
    [
      { :version => 'v5_0', :valid => true },
      { :version => 'v5.0', :valid => true },
      { :version => 'v3_2', :valid => true },
      { :version => 'invalid', :valid => false },
      { :version => '', :valid => false },
      { :version => nil, :valid => false },
      { :version => '? string:v2 ?', :valid => false }
    ].each do |args|
      it "#{args[:version]}, #{args[:valid]}" do
        expect(described_class.api_version_valid?(args[:version])).to eq(args[:valid])
      end
    end
  end

  context '.raw_connect' do
    before do
      @ems = FactoryBot.create(:ems_nuage_network_with_authentication, :hostname => 'host', :port => 8000, :api_version => 'v5_0')
    end

    it 'connects over insecure channel' do
      expect(ManageIQ::Providers::Nuage::NetworkManager::VsdClient).to receive(:new).with("http://host:8000/nuage/api/v5_0", "testuser", "secret")
      @ems.connect
    end

    it 'connects over secure channel without validation' do
      @ems.security_protocol = 'ssl'
      expect(ManageIQ::Providers::Nuage::NetworkManager::VsdClient).to receive(:new).with("https://host:8000/nuage/api/v5_0", "testuser", "secret")
      @ems.connect
    end

    it 'connects over secure channel' do
      @ems.security_protocol = 'ssl-with-validation'
      expect(ManageIQ::Providers::Nuage::NetworkManager::VsdClient).to receive(:new).with("https://host:8000/nuage/api/v5_0", "testuser", "secret")
      @ems.connect
    end

    it 'uses correct API version' do
      @ems.api_version = 'v4_0'
      expect(ManageIQ::Providers::Nuage::NetworkManager::VsdClient).to receive(:new).with("http://host:8000/nuage/api/v4_0", "testuser", "secret")
      @ems.connect
    end

    it 'raises error for invalid API version' do
      params = { :protocol => '', :hostname => '', :api_version => 'invalid'}
      expect { described_class.raw_connect('user', 'pass', params) }.to raise_error(MiqException::MiqInvalidCredentialsError)
    end
  end

  context 'validation' do
    before do
      @ems = FactoryBot.create(:ems_nuage_network_with_authentication)
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

    context 'AMQP connection' do
      before do
        @conn = double('connection', :handler => handler)
        allow(Qpid::Proton::Container).to receive(:new).and_return(@conn)

        creds = {}
        creds[:amqp] = {:userid => "amqp_user", :password => "amqp_password"}
        @ems.endpoints << Endpoint.create(:role => 'amqp', :hostname => 'amqp_hostname', :port => '5672')
        @ems.update_authentication(creds, :save => false)
      end

      let(:handler) { double('handler') }

      it 'verifies AMQP credentials' do
        allow(@conn).to receive(:run).and_return(true)
        expect(handler).to receive(:raise_for_error)
        expect(@ems.verify_credentials(:amqp)).to be_truthy
      end

      it 'handles connection errors' do
        allow(@conn).to receive(:run).and_raise(StandardError, 'connection error')
        expect { @ems.verify_credentials(:amqp) }.to raise_error(StandardError)
      end
    end
  end

  context 'translate_exception' do
    before do
      @ems = FactoryBot.build(:ems_nuage_network, :hostname => "host", :ipaddress => "::1")

      creds = {:default => {:userid => "fake_user", :password => "fake_password"}}
      @ems.update_authentication(creds, :save => false)
    end

    it "preserves and logs message for unknown exceptions" do
      allow(@ems).to receive(:with_provider_connection).and_raise(StandardError, "unlikely")

      expect($nuage_log).to receive(:error).with(/unlikely/)
      expect { @ems.verify_credentials }.to raise_error(MiqException::MiqEVMLoginError, /Unexpected.*unlikely/)
    end

    it 'handles Unauthorized' do
      exception = Excon::Errors::Unauthorized.new('unauthorized')
      allow(@ems).to receive(:with_provider_connection).and_raise(exception)
      expect { @ems.verify_credentials }.to raise_error(MiqException::MiqInvalidCredentialsError, /Login failed/)
    end

    it 'handles Timeout' do
      exception = Excon::Errors::Timeout.new
      allow(@ems).to receive(:with_provider_connection).and_raise(exception)
      expect { @ems.verify_credentials }.to raise_error(MiqException::MiqUnreachableError, /Login attempt timed out/)
    end

    it 'handles SocketError' do
      exception = Excon::Errors::SocketError.new
      allow(@ems).to receive(:with_provider_connection).and_raise(exception)
      expect { @ems.verify_credentials }.to raise_error(MiqException::MiqHostError, /Socket error/)
    end

    it 'handles MiqInvalidCredentialsError' do
      exception = MiqException::MiqInvalidCredentialsError.new('invalid credentials')
      allow(@ems).to receive(:with_provider_connection).and_raise(exception)
      expect { @ems.verify_credentials }.to raise_error(MiqException::MiqInvalidCredentialsError, /invalid credentials/)
    end

    it 'handles MiqHostError' do
      exception = MiqException::MiqHostError.new('invalid host')
      allow(@ems).to receive(:with_provider_connection).and_raise(exception)
      expect { @ems.verify_credentials }.to raise_error(MiqException::MiqHostError, /invalid host/)
    end

    it 'handles Net::HTTPBadResponse' do
      exception = Net::HTTPBadResponse.new
      allow(@ems).to receive(:with_provider_connection).and_raise(exception)
      expect { @ems.verify_credentials }.to raise_error(MiqException::MiqEVMLoginError, /Login failed due to a bad security protocol, hostname or port./)
    end
  end

  context '#authentications_to_validate' do
    it 'only :default is validated by default' do
      ems = FactoryBot.build(:ems_nuage_network, :hostname => "host", :ipaddress => "::1")
      creds = {:default => {:userid => "user", :password => "password"}}
      ems.update_authentication(creds, :save => false)

      expect(ems.authentications_to_validate).to eq([:default])
    end

    it 'validates :default and :amqp when both auths are given' do
      ems = FactoryBot.build(:ems_nuage_network_with_authentication, :hostname => "host", :ipaddress => "::1")
      creds = {:amqp => {:userid => "amqp_user", :password => "amqp_password"}}
      ems.update_authentication(creds, :save => false)

      expect(ems.authentications_to_validate).to eq([:default, :amqp])
    end
  end

  context '.event_monitor_class' do
    it 'uses valid event catcher' do
      expect(ManageIQ::Providers::Nuage::NetworkManager.event_monitor_class).to eq(ManageIQ::Providers::Nuage::NetworkManager::EventCatcher)
    end
  end

  context '.base_url' do
    it 'builds insecure URL' do
      expect(described_class.base_url(nil, 'hostname', 8443)).to eq('http://hostname:8443')
    end

    it 'builds insecure ssl URL' do
      expect(described_class.base_url('ssl', 'hostname', 8443)).to eq('https://hostname:8443')
    end

    it 'builds secure URL' do
      expect(described_class.base_url('ssl-with-validation', 'hostname', 8443)).to eq('https://hostname:8443')
    end

    it 'builds correct IPv6 URL' do
      expect(described_class.base_url('ssl-with-validation', '::1', 8443)).to eq('https://[::1]:8443')
    end
  end

  context '.auth_url' do
    it 'builds insecure URL' do
      expect(described_class.auth_url(nil, 'hostname', 8443, 'v5')).to eq('http://hostname:8443/nuage/api/v5')
    end

    it 'builds insecure ssl URL' do
      expect(described_class.auth_url('ssl', 'hostname', 8443, 'v5')).to eq('https://hostname:8443/nuage/api/v5')
    end

    it 'builds secure URL' do
      expect(described_class.auth_url('ssl-with-validation', 'hostname', 8443, 'v5')).to eq('https://hostname:8443/nuage/api/v5')
    end

    it 'builds correct IPv6 URL' do
      expect(described_class.auth_url('ssl-with-validation', '::1', 8443, 'v5')).to eq('https://[::1]:8443/nuage/api/v5')
    end
  end

  context '#event_monitor_options' do
    before(:each) do
      @ems = FactoryBot.build(:ems_nuage_network, :hostname => "host", :ipaddress => "::1")
      @creds = {:amqp => {:userid => "amqp_user", :password => "amqp_pass"}}
      @ems.endpoints << Endpoint.create(:role => 'amqp', :hostname => 'amqp_hostname', :port => '5672')
      @ems.update_authentication(@creds, :save => false)
    end

    it 'returns options with a single endpoint' do
      opts = @ems.event_monitor_options

      expect(opts).to include(
        :urls     => ['amqp_hostname:5672'],
        :user     => 'amqp_user',
        :password => 'amqp_pass'
      )
    end

    it 'returns options with a fallback URLs' do
      @ems.endpoints << Endpoint.create(:role => 'amqp_fallback1', :hostname => 'amqp_hostname1', :port => '5672')
      @ems.endpoints << Endpoint.create(:role => 'amqp_fallback2', :hostname => 'amqp_hostname2', :port => '5672')

      opts = @ems.event_monitor_options

      expect(opts[:urls]).to include('amqp_hostname:5672',
                                     'amqp_hostname1:5672',
                                     'amqp_hostname2:5672')
    end
  end

  it '.name' do
    ems = FactoryBot.create(:ems_nuage_network_with_authentication, :name => 'nuage')
    expect(ems.name).to eq('nuage')
  end

  describe 'ansible' do
    let(:ems) do
      ems = FactoryBot.create(:ems_nuage_network_with_authentication, :api_version => 'v5.0')
      ems.default_authentication.userid = 'user'
      ems.default_authentication.password = 'pass'
      ems.default_endpoint.security_protocol = 'ssl'
      ems.default_endpoint.hostname = 'nuage.demo'
      ems
    end

    it '.ansible_env_vars' do
      expect(ems.ansible_env_vars).to eq({})
    end

    describe '.ansible_extra_vars' do
      let(:extra_vars) { ems.ansible_extra_vars(params) }
      let(:params)     { {} }
      let(:nuage_auth) { extra_vars[:nuage_auth] }

      it 'default vars' do
        expect(extra_vars.keys).to eq([:nuage_auth])
        expect(nuage_auth).to eq(
          :api_username   => 'user',
          :api_password   => 'pass',
          :api_enterprise => 'csp',
          :api_version    => 'v5_0',
          :api_url        => 'https://nuage.demo'
        )
      end

      context 'with custom vars' do
        let(:params) { { :test => 'test', :demo => 'demo' } }

        it do
          expect(extra_vars.keys).to eq(%i(nuage_auth test demo))
          expect(extra_vars[:test]).to eq('test')
          expect(extra_vars[:demo]).to eq('demo')
        end
      end
    end

    it '.ansible_root' do
      expect(ems.ansible_root.to_s).to end_with('/manageiq-providers-nuage/content/ansible_runner')
    end

    it '.playbook' do
      expect(ems.playbook('play.yaml').to_s).to end_with('/manageiq-providers-nuage/content/ansible_runner/play.yaml')
    end
  end

  describe 'delegates that usually point to cloud manager' do
    %i[
      flavors
      cloud_resource_quotas
      cloud_volumes
      cloud_volume_snapshots
      cloud_object_store_containers
      cloud_object_store_objects
      key_pairs
      orchestration_stacks
      orchestration_stacks_resources
      direct_orchestration_stacks
      resource_groups
      vms
      total_vms
      vms_and_templates
      total_vms_and_templates
      miq_templates
      total_miq_templates
      hosts
    ].each do |rel|
      it "##{rel}" do
        expect(subject.send(rel).count).to eq(0)
      end
    end
  end
end
