class ManageIQ::Providers::Nuage::NetworkManager < ManageIQ::Providers::NetworkManager
  include SupportsFeatureMixin
  require_nested :EventCatcher
  require_nested :EventParser
  require_nested :RefreshWorker
  require_nested :Refresher
  require_nested :VsdClient
  require_nested :CloudTenant
  require_nested :NetworkRouter
  require_nested :CloudNetwork
  require_nested :CloudSubnet
  require_nested :CloudSubnetL3
  require_nested :CloudSubnetL2
  require_nested :SecurityGroup
  require_nested :FloatingIp
  require_nested :NetworkPort

  supports :ems_network_new

  include Vmdb::Logging
  include ManageIQ::Providers::Nuage::ManagerMixin

  def self.ems_type
    @ems_type ||= "nuage_network".freeze
  end

  def self.description
    @description ||= "Nuage Network Manager".freeze
  end

  def authentications_to_validate
    at = [:default]
    at << :amqp if has_authentication_type?(:amqp)
    at
  end

  def supported_auth_types
    %w(default amqp)
  end

  def supports_authentication?(authtype)
    supported_auth_types.include?(authtype.to_s)
  end

  class << self
    def event_monitor_class
      ManageIQ::Providers::Nuage::NetworkManager::EventCatcher
    end

    def l2_cloud_subnet_type
      'ManageIQ::Providers::Nuage::NetworkManager::CloudSubnetL2'
    end

    def l3_cloud_subnet_type
      'ManageIQ::Providers::Nuage::NetworkManager::CloudSubnetL3'
    end

    def floating_cloud_network_type
      'ManageIQ::Providers::Nuage::NetworkManager::CloudNetwork::Floating'
    end

    def bridge_network_port_type
      'ManageIQ::Providers::Nuage::NetworkManager::NetworkPort::Bridge'
    end

    def container_network_port_type
      'ManageIQ::Providers::Nuage::NetworkManager::NetworkPort::Container'
    end

    def host_network_port_type
      'ManageIQ::Providers::Nuage::NetworkManager::NetworkPort::Host'
    end

    def vm_network_port_type
      'ManageIQ::Providers::Nuage::NetworkManager::NetworkPort::Vm'
    end
  end

  def name
    self[:name]
  end

  def cloud_tenants
    ::CloudTenant.where(:ems_id => id)
  end

  def l3_cloud_subnets
    cloud_subnets.where(:type => self.class.l3_cloud_subnet_type)
  end

  def l2_cloud_subnets
    cloud_subnets.where(:type => self.class.l2_cloud_subnet_type)
  end
end
