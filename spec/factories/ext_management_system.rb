FactoryBot.define do
  factory :ems_nuage_with_vcr_authentication, :parent => :ems_nuage_network do
    zone do
      _guid, _server, zone = EvmSpecHelper.create_guid_miq_server_zone
      zone
    end

    after(:build) do |ems|
      ems.hostname = VcrSecrets.nuage.host
    end

    after(:create) do |ems|
      userid   = VcrSecrets.nuage.userid
      password = VcrSecrets.nuage.password

      cred = {
        :userid   => userid,
        :password => password
      }

      ems.authentications << FactoryBot.create(:authentication, cred)
    end
  end

  factory :ems_nuage_network_with_authentication,
          :parent => :ems_nuage_network do
    after :create do |x|
      x.authentications << FactoryBot.create(:authentication)
      x.authentications << FactoryBot.create(:authentication, :authtype => "amqp")
      x.endpoints       << FactoryBot.create(:endpoint, :role => "amqp")
    end
  end
end
