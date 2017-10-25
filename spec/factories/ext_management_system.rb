FactoryGirl.define do
  factory :ems_nuage_with_vcr_authentication, :parent => :ems_nuage_network do
    zone do
      _guid, _server, zone = EvmSpecHelper.create_guid_miq_server_zone
      zone
    end

    after(:build) do |ems|
      ems.hostname = Rails.application.secrets.nuage_network.try(:[], 'host') || 'nuagenetworkhost'
    end

    after(:create) do |ems|
      userid   = Rails.application.secrets.nuage_network.try(:[], 'userid') || 'NUAGE_USER_ID'
      password = Rails.application.secrets.nuage_network.try(:[], 'password') || 'NUAGE_PASSWORD'

      cred = {
        :userid   => userid,
        :password => password
      }

      ems.authentications << FactoryGirl.create(:authentication, cred)
    end
  end

  factory :ems_nuage_network_with_authentication,
          :parent => :ems_nuage_network do
    after :create do |x|
      x.authentications << FactoryGirl.create(:authentication)
      x.authentications << FactoryGirl.create(:authentication, :authtype => "amqp")
    end
  end
end
