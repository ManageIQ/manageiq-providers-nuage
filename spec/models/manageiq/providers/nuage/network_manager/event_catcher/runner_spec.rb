describe ManageIQ::Providers::Nuage::NetworkManager::EventCatcher::Runner do
  context 'EMS without AMQP credentials' do
    before do
      @ems = FactoryGirl.build(:ems_nuage_network, :hostname => "host", :ipaddress => "::1")
      @creds = {:amqp => {:userid => "amqp_user", :password => "amqp_pass"}}
      @ems.update_authentication(@creds, :save => false)

      allow_any_instance_of(described_class).to receive(:initialize)
      @rr = described_class.new
      @rr.instance_variable_set(:@ems, @ems)
    end

    it 'should have falsey amqp?' do
      expect(@rr.amqp?).to be_falsey
    end
  end

  context 'EMS with AMQP credentials' do
    before do
      @ems = FactoryGirl.build(:ems_nuage_network, :hostname => "host", :ipaddress => "::1")
      @creds = {:amqp => {:userid => "amqp_user", :password => "amqp_pass"}}
      @ems.endpoints << Endpoint.create(:role => 'amqp', :hostname => 'amqp_hostname', :port => '5672')
      @ems.update_authentication(@creds, :save => false)

      allow_any_instance_of(described_class).to receive(:initialize)
      @rr = described_class.new
      @rr.instance_variable_set(:@ems, @ems)
    end

    it 'should have truthy amqp?' do
      expect(@rr.amqp?).to be_truthy
    end
  end
end
