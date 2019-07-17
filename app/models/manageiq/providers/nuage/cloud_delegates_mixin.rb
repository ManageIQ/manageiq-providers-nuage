module ManageIQ::Providers::Nuage::CloudDelegatesMixin
  def flavors
    Flavor.none
  end

  def cloud_resource_quotas
    CloudResourceQuota.none
  end

  def cloud_volumes
    CloudVolume.none
  end

  def cloud_volume_snapshots
    CloudVolumeSnapshot.none
  end

  def cloud_object_store_containers
    CloudObjectStoreContainer.none
  end

  def cloud_object_store_objects
    CloudObjectStoreObject.none
  end

  def key_pairs
    ManageIQ::Providers::CloudManager::AuthKeyPair.none
  end

  def orchestration_stacks
    OrchestrationStack.none
  end
  alias direct_orchestration_stacks orchestration_stacks

  def orchestration_stacks_resources
    OrchestrationStackResource.none
  end

  def resource_groups
    ResourceGroup.none
  end

  def vms
    Vm.none
  end
  alias total_vms vms
  alias vms_and_templates vms
  alias total_vms_and_templates vms

  def miq_templates
    MiqTemplate.none
  end
  alias total_miq_templates miq_templates

  def hosts
    Host.none
  end
end
