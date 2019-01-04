FactoryBot.define do
  factory :floating_ip_nuage,
          :class  => "ManageIQ::Providers::Nuage::NetworkManager::FloatingIp",
          :parent => :floating_ip
end
