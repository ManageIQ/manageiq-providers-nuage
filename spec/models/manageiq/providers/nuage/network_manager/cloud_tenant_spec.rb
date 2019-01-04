describe ManageIQ::Providers::Nuage::NetworkManager::CloudTenant do
  let(:ems)    { FactoryBot.create(:ems_nuage_network_with_authentication) }
  let(:tenant) { FactoryBot.create(:cloud_tenant_nuage, :ems_id => ems.id) }
  let(:router) { FactoryBot.create(:network_router_nuage, :ems_id => ems.id, :cloud_tenant_id => tenant.id) }
  let(:subnet) { FactoryBot.create(:cloud_subnet_l3_nuage, :ems_id => ems.id, :cloud_tenant_id => tenant.id, :network_router_id => router.id) }
  let(:ip)     { FactoryBot.create(:floating_ip_nuage, :ems_id => ems.id, :cloud_tenant_id => tenant.id, :network_router_id => router.id) }
  let(:group)  { FactoryBot.create(:security_group_nuage, :ems_id => ems.id, :cloud_tenant_id => tenant.id) }
  let(:port) do
    FactoryBot.create(
      :network_port_bridge_nuage,
      :ems_id          => ems.id,
      :cloud_tenant_id => tenant.id,
      :cloud_subnets   => [subnet],
      :floating_ip     => ip,
      :security_groups => [group]
    )
  end

  describe '.destroy' do
    before do
      assert_hierarchy
      assert_table_counts
    end

    it 'cloud_tenant.destroy' do
      tenant.destroy
      assert_table_counts(:tenants => 0, :routers => 0, :subnets => 0, :ports => 0, :ips => 0, :groups => 0)
    end

    it 'network_router.destroy' do
      router.destroy
      assert_table_counts(:tenants => 1, :routers => 0, :subnets => 0, :ports => 0, :ips => 0, :groups => 1)
    end

    it 'cloud_subnet.destroy' do
      subnet.destroy
      assert_table_counts(:tenants => 1, :routers => 1, :subnets => 0, :ports => 0, :ips => 1, :groups => 1)
    end

    it 'network_port.destroy' do
      port.destroy
      assert_table_counts(:tenants => 1, :routers => 1, :subnets => 1, :ports => 0, :ips => 1, :groups => 1)
    end

    it 'floating_ip.destroy' do
      ip.destroy
      assert_table_counts(:tenants => 1, :routers => 1, :subnets => 1, :ports => 1, :ips => 0, :groups => 1)
    end

    it 'security_group.destroy' do
      group.destroy
      assert_table_counts(:tenants => 1, :routers => 1, :subnets => 1, :ports => 1, :ips => 1, :groups => 0)
    end
  end

  def assert_hierarchy
    expect(ems.cloud_tenants).to eq([tenant])
    expect(ems.network_routers).to eq([router])
    expect(ems.cloud_subnets).to eq([subnet])
    expect(ems.network_ports).to eq([port])
    expect(ems.floating_ips).to eq([ip])
    expect(ems.security_groups).to eq([group])

    expect(tenant.network_routers).to eq([router])
    expect(tenant.cloud_subnets).to eq([subnet])
    expect(tenant.network_ports).to eq([port])
    expect(tenant.floating_ips).to eq([ip])
    expect(tenant.security_groups).to eq([group])

    expect(router.cloud_subnets).to eq([subnet])
    expect(router.network_ports).to eq([port])
    expect(router.floating_ips).to eq([ip])

    expect(subnet.network_ports).to eq([port])

    expect(port.floating_ips).to eq([ip])
    expect(port.security_groups).to eq([group])
  end

  def assert_table_counts(tenants: 1, routers: 1, subnets: 1, ports: 1, ips: 1, groups: 1)
    expect(CloudTenant.count).to eq(tenants)
    expect(NetworkRouter.count).to eq(routers)
    expect(CloudSubnet.count).to eq(subnets)
    expect(NetworkPort.count).to eq(ports)
    expect(CloudSubnetNetworkPort.count).to eq(ports)
    expect(FloatingIp.count).to eq(ips)
    expect(SecurityGroup.count).to eq(groups)
  end
end
