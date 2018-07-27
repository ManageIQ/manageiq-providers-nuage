class ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet < ::CloudSubnet
  before_destroy :remove_network_ports, :prepend => true
  supports :delete

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

    Ansible::Runner.run(
      ext_management_system.ansible_env_vars,
      ext_management_system.ansible_extra_vars(:id => ems_ref, :kind => kind),
      ext_management_system.playbook('remove-subnet.yml')
    )

    $nuage_log.info("Done deleting Cloud Subnet (ems_ref = #{ems_ref})")
  rescue StandardError => e
    $nuage_log.error("Error deleting Cloud Subnet: #{e}")
    raise MiqException::MiqCloudSubnetDeleteError
  end

  def kind
    'L3'
  end
end
