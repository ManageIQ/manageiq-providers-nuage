class ManageIQ::Providers::Nuage::NetworkManager::CloudTenant < ::CloudTenant
  def l3_cloud_subnets
    cloud_subnets.where(:type => self.class.parent.l3_cloud_subnet_type)
  end

  def l2_cloud_subnets
    cloud_subnets.where(:type => self.class.parent.l2_cloud_subnet_type)
  end
end
