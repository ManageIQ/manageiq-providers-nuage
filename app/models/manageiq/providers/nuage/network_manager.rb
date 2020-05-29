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
  require_nested :SecurityGroup
  require_nested :FloatingIp
  require_nested :NetworkPort

  supports :ems_network_new

  include Vmdb::Logging
  include ManageIQ::Providers::Nuage::ManagerMixin

  # FIXME: remove this after the provider doesn't belong to a parent_manager
  def self.supported_for_create?
    true
  end

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
      'ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet::L2'
    end

    def l3_cloud_subnet_type
      'ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet::L3'
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

  def cloud_subnets_by_extra_attr(key, value)
    cloud_subnets.where('extra_attributes ~* ?', "#{key}: #{value}\n")
  end

  def ansible_env_vars
    {}
  end

  def ansible_extra_vars(extra = {})
    {
      :nuage_auth => {
        :api_username   => default_authentication.userid,
        :api_password   => default_authentication.password,
        :api_enterprise => 'csp', # TODO(miha-plesko): can this really be hard-coded?
        :api_version    => api_version.to_s.sub('.', '_'),
        :api_url        => self.class.base_url(
          default_endpoint.security_protocol,
          default_endpoint.hostname,
          default_endpoint.port
        )
      }
    }.merge(extra)
  end

  def ansible_root
    ManageIQ::Providers::Nuage::Engine.root.join("content/ansible_runner")
  end

  def playbook(name)
    ansible_root.join(name)
  end

  # TODO(miha-plesko): move to core
  def create_cloud_subnet_queue(userid, options = {})
    task_opts = {
      :action => "creating Cloud Subnet for user #{userid}",
      :userid => userid
    }
    queue_opts = {
      :class_name  => self.class.name,
      :method_name => 'create_cloud_subnet',
      :instance_id => id,
      :priority    => MiqQueue::NORMAL_PRIORITY,
      :role        => 'ems_operations',
      :zone        => my_zone,
      :args        => [options]
    }
    MiqTask.generic_action_with_callback(task_opts, queue_opts)
  end

  def create_cloud_subnet(options)
    self.class::CloudSubnet.raw_create_cloud_subnet(self, options)
  end
end
