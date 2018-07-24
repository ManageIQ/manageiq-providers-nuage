FactoryGirl.define do
  factory :network_router_nuage,
          :class  => "ManageIQ::Providers::Nuage::NetworkManager::NetworkRouter",
          :parent => :network_router
end
