FactoryGirl.define do
  factory :cloud_network_floating_nuage,
          :class  => "ManageIQ::Providers::Nuage::NetworkManager::CloudNetwork::Floating",
          :parent => :cloud_network
end
