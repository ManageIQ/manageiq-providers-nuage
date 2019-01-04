FactoryBot.define do
  factory :security_group_nuage,
          :class  => "ManageIQ::Providers::Nuage::NetworkManager::SecurityGroup",
          :parent => :security_group
end
