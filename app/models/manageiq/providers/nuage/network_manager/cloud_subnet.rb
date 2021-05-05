class ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet < ::CloudSubnet
  has_many :security_groups, :dependent => :destroy

  include ManageIQ::Providers::Nuage::AnsibleCrudMixin

  before_destroy :remove_network_ports, :prepend => true

  supports :delete
  supports :create

  def self.params_for_create(ems)
    {
      :fields => [
        {
          :component    => 'select',
          :name         => 'cloud_network_id',
          :id           => 'cloud_network_id',
          :label        => _('Network'),
          :isRequired   => true,
          :validate     => [{:type => 'required'}],
          :includeEmpty => true,
          :options      => ems.cloud_networks.map do |cvt|
            {
              :label => cvt.name,
              :value => cvt.id,
            }
          end,
        },
        {
          :component => 'text-field',
          :id        => 'gateway',
          :name      => 'gateway',
          :label     => _('Gateway'),
        },
      ],
    }
  end

  def remove_network_ports
    network_ports.each(&:destroy)
  end

  def delete_cloud_subnet_queue(userid)
    task_opts = {
      :action => "deleting Cloud Subnet for user #{userid}",
      :userid => userid
    }
    queue_opts = {
      :class_name  => self.class.name,
      :method_name => 'delete_cloud_subnet',
      :instance_id => id,
      :priority    => MiqQueue::NORMAL_PRIORITY,
      :role        => 'ems_operations',
      :zone        => ext_management_system.my_zone,
      :args        => []
    }
    MiqTask.generic_action_with_callback(task_opts, queue_opts)
  end

  def raw_delete_cloud_subnet
    $nuage_log.info("Deleting Cloud Subnet (ems_ref = #{ems_ref})")

    response = Ansible::Runner.run(
      ext_management_system.ansible_env_vars,
      ext_management_system.ansible_extra_vars(:id => ems_ref, :kind => kind),
      ext_management_system.playbook('remove-subnet.yml')
    )
    self.class.ansible_raise_for_status(response)

    $nuage_log.info("Done deleting Cloud Subnet (ems_ref = #{ems_ref})")
  rescue StandardError => e
    $nuage_log.error("Error deleting Cloud Subnet: #{e}")
    raise MiqException::MiqCloudSubnetDeleteError
  end

  def kind
    'L3'
  end

  def self.raw_create_cloud_subnet(ext_management_system, options)
    $nuage_log.info("Create Cloud Subnet (options = #{options})")
    response = Ansible::Runner.run(
      ext_management_system.ansible_env_vars,
      ext_management_system.ansible_extra_vars(
        :domain_id         => options[:router_ref],
        :subnet_attributes => {
          :name    => options[:name],
          :address => options[:address],
          :netmask => options[:netmask],
          :gateway => options[:gateway]
        }
      ),
      ext_management_system.playbook('create-subnet.yml')
    )
    ansible_raise_for_status(response)
    $nuage_log.info('Done creating Cloud Subnet')

    subnet = ansible_stats(response, 'created_entity', 'entities', 0)
    {:ems_ref => subnet['ID'], :name => subnet['name']}
  rescue StandardError => e
    $nuage_log.error("Error creating Cloud Subnet: #{e}")
    raise MiqException::MiqCloudSubnetCreateError
  end
end
