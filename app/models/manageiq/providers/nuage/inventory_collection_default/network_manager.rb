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
          :cloud_tenant,
          :network_router
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
          :cloud_tenant
        ]
      }

      super(attributes.merge!(extra_attributes))
    end

    def cloud_tenants(extra_attributes = {})
      attributes = {
        :model_class                 => ::ManageIQ::Providers::Nuage::NetworkManager::CloudTenant,
        :association                 => :cloud_tenants,
        :builder_params              => {
          :ems_id => ->(persister) { persister.manager.id },
        },
        :inventory_object_attributes => [
          :type,
          :ems_id,
          :ems_ref,
          :name,
          :description
        ]
      }

      attributes.merge!(extra_attributes)
    end

    def network_routers(extra_attributes = {})
      attributes = {
        :model_class                 => ::ManageIQ::Providers::Nuage::NetworkManager::NetworkRouter,
        :association                 => :network_routers,
        :builder_params              => {
          :ems_id => ->(persister) { persister.manager.id },
        },
        :inventory_object_attributes => [
          :type,
          :name,
          :cloud_tenant
        ]
      }

      attributes.merge!(extra_attributes)
    end
  end
end
