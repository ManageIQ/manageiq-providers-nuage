class ManageIQ::Providers::Nuage::NetworkManager::NetworkRouter < ::NetworkRouter
  has_many :floating_ips, :dependent => :destroy

  # TODO(miha-plesko): remove when https://github.com/ManageIQ/manageiq-schema/pull/217 is merged
  def floating_ips
    FloatingIp.none
  end
end
