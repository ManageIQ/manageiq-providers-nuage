class ManageIQ::Providers::Nuage::Inventory::Persister::TargetCollection < ManageIQ::Providers::Nuage::Inventory::Persister
  def initialize_inventory_collections
    add_inventory_collections_with_references(
      network,
      %i(cloud_tenants network_routers cloud_subnets security_groups),
      :parent => manager
    )
  end

  private

  def add_inventory_collections_with_references(inventory_collections_data, names, options = {})
    names.each do |name|
      add_inventory_collection_with_references(inventory_collections_data, name, references(name), options)
    end
  end

  def add_inventory_collection_with_references(inventory_collections_data, name, manager_refs, options = {})
    options = inventory_collections_data.send(
      name,
      :manager_uuids => manager_refs,
      :strategy      => strategy,
      :targeted      => true
    ).merge(options)

    add_inventory_collection(options)
  end

  def references(collection)
    target.manager_refs_by_association.try(:[], collection).try(:[], :ems_ref).try(:to_a) || []
  end

  def targeted
    true
  end

  def strategy
    :local_db_find_missing_references
  end
end
