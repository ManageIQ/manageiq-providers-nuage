FactoryGirl.define do
  factory :cloud_subnet_nuage,
          :class  => "ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet",
          :parent => :cloud_subnet

  factory :cloud_subnet_l3_nuage,
          :class  => "ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet::L3",
          :parent => :cloud_subnet_nuage

  factory :cloud_subnet_l2_nuage,
          :class  => "ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet::L2",
          :parent => :cloud_subnet_nuage
end
