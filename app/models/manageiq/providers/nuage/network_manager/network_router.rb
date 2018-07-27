class ManageIQ::Providers::Nuage::NetworkManager::NetworkRouter < ::NetworkRouter
  has_many :floating_ips,  :dependent => :destroy
  has_many :cloud_subnets, :dependent => :destroy
end
