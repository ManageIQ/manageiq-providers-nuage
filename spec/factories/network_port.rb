FactoryBot.define do
  factory :network_port_bridge_nuage,
          :class  => "ManageIQ::Providers::Nuage::NetworkManager::NetworkPort::Bridge",
          :parent => :network_port

  factory :network_port_container_nuage,
          :class  => "ManageIQ::Providers::Nuage::NetworkManager::NetworkPort::Container",
          :parent => :network_port

  factory :network_port_host_nuage,
          :class  => "ManageIQ::Providers::Nuage::NetworkManager::NetworkPort::Host",
          :parent => :network_port

  factory :network_port_vm_nuage,
          :class  => "ManageIQ::Providers::Nuage::NetworkManager::NetworkPort::Vm",
          :parent => :network_port
end
