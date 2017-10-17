class ManageIQ::Providers::Nuage::Builder
  class << self
    def build_inventory(ems, target)
      case target
      when ManageIQ::Providers::Nuage::NetworkManager
        network_manager_inventory(ems, target)
      when ManagerRefresh::TargetCollection
        inventory(
          ems,
          target,
          ManageIQ::Providers::Nuage::Inventory::Collector::TargetCollection,
          ManageIQ::Providers::Nuage::Inventory::Persister::TargetCollection,
          [ManageIQ::Providers::Nuage::Inventory::Parser::NetworkManager]
        )
      else
        # Fallback to ems refresh
        network_manager_inventory(ems, target)
      end
    end

    private

    def network_manager_inventory(ems, target)
      inventory(
        ems,
        target,
        ManageIQ::Providers::Nuage::Inventory::Collector::NetworkManager,
        ManageIQ::Providers::Nuage::Inventory::Persister::NetworkManager,
        [ManageIQ::Providers::Nuage::Inventory::Parser::NetworkManager]
      )
    end

    def inventory(manager, raw_target, collector_class, persister_class, parsers_classes)
      collector = collector_class.new(manager, raw_target)
      persister = persister_class.new(manager, raw_target)

      ::ManageIQ::Providers::Nuage::Inventory.new(
        persister,
        collector,
        parsers_classes.map(&:new)
      )
    end
  end
end
