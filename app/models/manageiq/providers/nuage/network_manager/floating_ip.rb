class ManageIQ::Providers::Nuage::NetworkManager::FloatingIp < ::FloatingIp
  supports :delete

  def delete_floating_ip_queue(userid)
    task_opts = {
      :action => "deleting Floating Ip for user #{userid}",
      :userid => userid
    }
    queue_opts = {
      :class_name  => self.class.name,
      :method_name => 'delete_floating_ip',
      :instance_id => id,
      :priority    => MiqQueue::NORMAL_PRIORITY,
      :role        => 'ems_operations',
      :zone        => ext_management_system.my_zone,
      :args        => []
    }
    MiqTask.generic_action_with_callback(task_opts, queue_opts)
  end

  # TODO: Move to core
  def delete_floating_ip
    raw_delete_floating_ip
  end

  def raw_delete_floating_ip
    $nuage_log.info("Deleting Floating Ip (ems_ref = #{ems_ref})")

    Ansible::Runner.run(
      ext_management_system.ansible_env_vars,
      ext_management_system.ansible_extra_vars(:id => ems_ref),
      ext_management_system.playbook('remove-floating-ip.yml')
    )

    $nuage_log.info("Done deleting Floating Ip (ems_ref = #{ems_ref})")
  rescue StandardError => e
    $nuage_log.error("Error deleting Floating Ip: #{e}")
    raise MiqException::MiqCloudSubnetDeleteError
  end
end
