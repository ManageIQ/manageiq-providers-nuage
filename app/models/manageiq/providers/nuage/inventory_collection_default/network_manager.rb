class ManageIQ::Providers::Nuage::InventoryCollectionDefault::NetworkManager < ManagerRefresh::InventoryCollectionDefault::NetworkManager
  class << self
    def cloud_subnets(extra_attributes = {})
      attributes = {
        :model_class                 => ::ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet,
        :inventory_object_attributes => [
          :type,
          :ems_id,
          :ems_ref,
          :name,
          :cidr,
          :network_protocol,
          :gateway,
          :dhcp_enabled,
          :extra_attributes,
          :network_group
        ]
      }

      super(attributes.merge!(extra_attributes))
    end

    def security_groups(extra_attributes = {})
      attributes = {
        :model_class                 => ::ManageIQ::Providers::Nuage::NetworkManager::SecurityGroup,
        :inventory_object_attributes => [
          :type,
          :ems_id,
          :ems_ref,
          :name,
          :network_group
        ]
      }

      super(attributes.merge!(extra_attributes))
    end

    def network_groups(extra_attributes = {})
      attributes = {
        :model_class                 => ::ManageIQ::Providers::Nuage::NetworkManager::NetworkGroup,
        :inventory_object_attributes => [
          :type,
          :ems_id,
          :ems_ref,
          :name,
          :status
        ]
      }

      # super(attributes.merge!(extra_attributes))
      super_network_groups(attributes.merge!(extra_attributes))
    end

    # TODO(miha-plesko) Remove this function once it gets merged into core repo i.e. once this PR gets merged:
    # https://github.com/ManageIQ/manageiq/pull/16136
    # Doing this, also make sure that `network_groups` function then calls `super` instead `super_network_groups`
    def super_network_groups(extra_attributes = {})
      attributes = {
        :model_class    => ::NetworkGroup,
        :association    => :network_groups,
        :builder_params => {
          :ems_id => ->(persister) { persister.manager.try(:network_manager).try(:id) || persister.manager.id },
        }
      }

      attributes.merge!(extra_attributes)
    end
  end
end
