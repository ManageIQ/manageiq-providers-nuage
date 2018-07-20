class ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet < ::CloudSubnet
  supports :delete
  supports :create

  def delete_cloud_subnet_queue(userid)
    task_opts = {
      :action => "deleting Cloud Subnet for user #{userid}",
      :userid => userid
    }
    queue_opts = {
      :class_name  => self.class.name,
      :method_name => 'raw_delete_cloud_subnet',
      :instance_id => id,
      :priority    => MiqQueue::HIGH_PRIORITY,
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
      ext_management_system.ansible_extra_vars(:id => ems_ref),
      ext_management_system.playbook('remove-subnet.yml')
    )

    $nuage_log.info("Done deleting Cloud Subnet (ems_ref = #{ems_ref})")
  rescue => e
    $nuage_log.error "Error deleting Cloud Subnet: #{e}"
    raise MiqException::MiqCloudSubnetDeleteError
  end

  def self.raw_create_cloud_subnet(ext_management_system, options)
    $nuage_log.info("Create Cloud Subnet (ems_ref = #{ems_ref})")

    # TODO: update UI to match what Nuage needs

    subnet = Ansible::Runner.run(
      ext_management_system.ansible_env_vars,
      ext_management_system.ansible_extra_vars(
        :domain_id => options[:router_id],
        :subnet_attributes => { :name => options[:name] }
      ),
      ext_management_system.playbook('remove-subnet.yml')
    )

    $nuage_log.info("Done creating Cloud Subnet (ems_ref = #{ems_ref})")

    # TODO: can playbook return value?

    {:ems_ref => subnet.id, :name => options[:name]}
  rescue => e
    $nuage_log.error "Error creating Cloud Subnet: #{e}"
    raise MiqException::MiqCloudSubnetCreateError
  end
end
