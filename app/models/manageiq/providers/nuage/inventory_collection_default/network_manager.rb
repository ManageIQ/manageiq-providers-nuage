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

      super(attributes.merge!(extra_attributes))
    end
  end
end
