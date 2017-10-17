FactoryGirl.define do
  factory :cloud_subnet_nuage,
          :class  => "ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet",
          :parent => :cloud_subnet
end
