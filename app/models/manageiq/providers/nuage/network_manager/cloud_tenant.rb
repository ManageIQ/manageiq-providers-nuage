class ManageIQ::Providers::Nuage::NetworkManager::CloudTenant < ::CloudTenant
  has_many   :security_groups, :dependent => :destroy
  has_many   :cloud_subnets,   :dependent => :destroy
  has_many   :network_ports,   :dependent => :destroy
  has_many   :network_routers, :dependent => :destroy
  has_many   :floating_ips,    :dependent => :destroy

  def l3_cloud_subnets
    cloud_subnets.where(:type => self.class.parent.l3_cloud_subnet_type)
  end

  def l2_cloud_subnets
    cloud_subnets.where(:type => self.class.parent.l2_cloud_subnet_type)
  end
end
