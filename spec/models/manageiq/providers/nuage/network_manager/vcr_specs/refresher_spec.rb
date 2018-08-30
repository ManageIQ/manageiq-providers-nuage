describe ManageIQ::Providers::Nuage::NetworkManager::Refresher do
  ALL_REFRESH_SETTINGS = [
    {
      :inventory_object_refresh => true,
      :inventory_collections    => {
        :saver_strategy => :default,
      },
    },
    {
      :inventory_object_refresh => true,
      :inventory_collections    => {
        :saver_strategy => :batch,
        :use_ar_object  => true,
      },
    },
    {
      :inventory_object_refresh => true,
      :inventory_collections    => {
        :saver_strategy => :batch,
        :use_ar_object  => false,
      },
    },
    {
      :inventory_object_saving_strategy => :recursive,
      :inventory_object_refresh         => true
    }
  ].freeze

  before(:each) do
    @ems = FactoryGirl.create(:ems_nuage_with_vcr_authentication, :port => 8443, :api_version => "v5_0", :security_protocol => "ssl-with-validation")
  end

  before(:each) do
    userid   = Rails.application.secrets.nuage_network.try(:[], 'userid') || 'NUAGE_USER_ID'
    password = Rails.application.secrets.nuage_network.try(:[], 'password') || 'NUAGE_PASSWORD'
    hostname = @ems.hostname

    # Ensure that VCR will obfuscate the basic auth
    VCR.configure do |c|
      # workaround for escaping host
      c.before_playback do |interaction|
        interaction.filter!(CGI.escape(hostname), hostname)
        interaction.filter!(CGI.escape('NUAGE_NETWORK_HOST'), 'nuagenetworkhost')
      end
      c.filter_sensitive_data('NUAGE_NETWORK_AUTHORIZATION') { Base64.encode64("#{userid}:#{password}").chomp }
    end
  end

  it ".ems_type" do
    expect(described_class.ems_type).to eq(:nuage_network)
  end

  describe "refresh" do
    let(:ems_amazon)          { FactoryGirl.create(:ems_amazon) }
    let!(:vm_amazon)          { FactoryGirl.create(:vm_amazon, :ems_id => ems_amazon.id, :ems_ref => 'ref-amazon-vm') }
    let(:tenant_ref1)         { "713d0ba0-dea8-44b4-8ac7-6cab9dc321a7" }
    let(:tenant_ref2)         { "e0819464-e7fc-4a37-b29a-e72da7b5956c" }
    let(:security_group_ref)  { "02e072ef-ca95-4164-856d-3ff177b9c13c" }
    let(:cloud_subnet_ref1)   { "d60d316a-c1ac-4412-813c-9652bdbc4e41" }
    let(:cloud_subnet_ref2)   { "debb9f88-f252-4c30-9a17-d6ae3865e365" }
    let(:l2_subnet_ref1)      { "3b733a41-774d-4aaa-8e64-588d5533a5c0" }
    let(:l2_subnet_ref2)      { "8efc78b0-df2a-4c6f-964b-463a9d106bed" }
    let(:router_ref)          { "75ad8ee8-726c-4950-94bc-6a5aab64631d" }
    let(:floating_ip_ref)     { "3a00891b-29ba-4f60-8f35-033d84aa1083" }
    let(:network_ref)         { "17b305a7-eec9-4492-acb9-20a1d63a8ba1" }
    let(:cont_port_ref)       { "dd9a4d57-2e24-427b-8aef-4d2925df47b2" }
    let(:vm_port_ref)         { "15d1369e-9553-4e83-8bb9-3a6c269f81ae" }
    let(:bridge_port_ref)     { "43b7faad-2c76-4945-9412-66a04bde7b6a" }
    let(:host_port_ref)       { "b19075d3-a797-4dcd-93be-de52b4247e46" }

    ALL_REFRESH_SETTINGS.each do |settings|
      context "with settings #{settings}" do
        before(:each) do
          stub_settings_merge(
            :ems_refresh => {
              :nuage_network => settings
            }
          )
        end

        it "will perform a full refresh" do
          2.times do # Run twice to verify that a second run with existing data does not change anything
            @ems.reload

            VCR.use_cassette(described_class.name.underscore, :allow_unused_http_interactions => true) do
              EmsRefresh.refresh(@ems)
            end

            @ems.reload
            assert_table_counts
            assert_ems
            assert_cloud_tenants
            assert_network_routers
            assert_security_groups
            assert_cloud_subnets
            assert_l2_cloud_subnets
            assert_floating_ips
            assert_cloud_networks
            assert_network_ports
          end
        end
      end
    end
  end

  def assert_table_counts
    expect(ExtManagementSystem.count).to eq(1 + 3) # nuage + 3*amazon (cloud, network, storage manager)
    expect(CloudTenant.count).to eq(2)
    expect(CloudNetwork.count).to eq(1)
    expect(SecurityGroup.count).to eq(1)
    expect(CloudSubnet.count).to eq(6)
    expect(FloatingIp.count).to eq(3)
    expect(NetworkPort.count).to eq(4)
    expect(NetworkRouter.count).to eq(1)
    expect(Vm.count).to eq(1) # artificial Amazon VM
  end

  def assert_ems
    expect(@ems.cloud_tenants.count).to eq(2)
    expect(@ems.security_groups.count).to eq(1)
    expect(@ems.cloud_subnets.count).to eq(6)
    expect(@ems.l3_cloud_subnets.count).to eq(2)
    expect(@ems.l2_cloud_subnets.count).to eq(4)

    expect(@ems.cloud_tenants.map(&:ems_ref))
      .to match_array([tenant_ref1, tenant_ref2])
    expect(@ems.security_groups.map(&:ems_ref))
      .to match_array([security_group_ref])
    expect(@ems.l3_cloud_subnets.map(&:ems_ref))
      .to match_array([cloud_subnet_ref1, cloud_subnet_ref2])
  end

  def assert_cloud_tenants
    g1 = CloudTenant.find_by(:ems_ref => tenant_ref1)
    expect(g1).to have_attributes(
      :name    => "Ansible-Test",
      :enabled => nil,
      :ems_id  => @ems.id,
      :type    => "ManageIQ::Providers::Nuage::NetworkManager::CloudTenant"
    )
    expect(g1.cloud_subnets.count).to eq(2)
    expect(g1.l3_cloud_subnets.count).to eq(0)
    expect(g1.l2_cloud_subnets.count).to eq(2)
    expect(g1.security_groups.count).to eq(0)

    g2 = CloudTenant.find_by(:ems_ref => tenant_ref2)
    expect(g2).to have_attributes(
      :name    => "XLAB",
      :enabled => nil,
      :ems_id  => @ems.id,
      :type    => "ManageIQ::Providers::Nuage::NetworkManager::CloudTenant"
    )
    expect(g2.cloud_subnets.count).to eq(4)
    expect(g2.l3_cloud_subnets.count).to eq(2)
    expect(g2.l2_cloud_subnets.count).to eq(2)
    expect(g2.security_groups.count).to eq(1)

    expect(g2.l3_cloud_subnets.map(&:ems_ref))
      .to match_array([cloud_subnet_ref1, cloud_subnet_ref2])
    expect(g2.security_groups.map(&:ems_ref))
      .to match_array([security_group_ref])
  end

  def assert_network_routers
    router = NetworkRouter.find_by(:ems_ref => router_ref)
    expect(router).to have_attributes(
      :name            => 'BaseL3',
      :ems_id          => @ems.id,
      :cloud_tenant_id => CloudTenant.find_by(:ems_ref => tenant_ref2).id,
      :type            => 'ManageIQ::Providers::Nuage::NetworkManager::NetworkRouter'
    )
  end

  def assert_security_groups
    g1 = SecurityGroup.find_by(:ems_ref => security_group_ref)
    expect(g1).to have_attributes(
      :name                   => "Test Policy Group",
      :description            => nil,
      :type                   => "ManageIQ::Providers::Nuage::NetworkManager::SecurityGroup",
      :ems_id                 => @ems.id,
      :cloud_network_id       => nil,
      :cloud_tenant_id        => CloudTenant.find_by(:ems_ref => tenant_ref2).id,
      :orchestration_stack_id => nil
    )
  end

  def assert_cloud_subnets
    s1 = CloudSubnet.find_by(:ems_ref => cloud_subnet_ref1)
    expect(s1).to have_attributes(
      :name                           => "Subnet 1",
      :ems_id                         => @ems.id,
      :availability_zone_id           => nil,
      :cloud_network_id               => nil,
      :cidr                           => "10.10.20.0/24",
      :status                         => nil,
      :dhcp_enabled                   => false,
      :gateway                        => "10.10.20.1",
      :network_protocol               => "ipv4",
      :cloud_tenant_id                => CloudTenant.find_by(:ems_ref => tenant_ref2).id,
      :dns_nameservers                => nil,
      :ipv6_router_advertisement_mode => nil,
      :ipv6_address_mode              => nil,
      :type                           => "ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet::L3",
      :network_router_id              => NetworkRouter.find_by(:ems_ref => router_ref).id,
      :parent_cloud_subnet_id         => nil,
      :extra_attributes               => {
        "domain_id"        => "75ad8ee8-726c-4950-94bc-6a5aab64631d",
        "zone_name"        => "Zone 1",
        "zone_id"          => "6256954b-9dd6-43ed-94ff-9daa683ab8b0",
        "template_id"      => nil,
        "zone_template_id" => nil
      }
    )

    s2 = CloudSubnet.find_by(:ems_ref => cloud_subnet_ref2)
    expect(s2).to have_attributes(
      :name                           => "Subnet 0",
      :ems_id                         => @ems.id,
      :availability_zone_id           => nil,
      :cloud_network_id               => nil,
      :cidr                           => "10.10.10.0/24",
      :status                         => nil,
      :dhcp_enabled                   => false,
      :gateway                        => "10.10.10.1",
      :network_protocol               => "ipv4",
      :cloud_tenant_id                => CloudTenant.find_by(:ems_ref => tenant_ref2).id,
      :dns_nameservers                => nil,
      :ipv6_router_advertisement_mode => nil,
      :ipv6_address_mode              => nil,
      :type                           => "ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet::L3",
      :network_router_id              => NetworkRouter.find_by(:ems_ref => router_ref).id,
      :parent_cloud_subnet_id         => nil,
      :extra_attributes               => {
        "domain_id"        => "75ad8ee8-726c-4950-94bc-6a5aab64631d",
        "zone_name"        => "Zone 0",
        "zone_id"          => "3b11a2d0-2082-42f1-92db-0b05264f372e",
        "template_id"      => "aaaaaaaa-aaaa-bbbb-bbbb-cccccccccccc",
        "zone_template_id" => "abababab-abab-abab-abab-abababababab"
      }
    )
  end

  def assert_l2_cloud_subnets
    s1 = CloudSubnet.find_by(:ems_ref => l2_subnet_ref1)
    expect(s1).to have_attributes(
      :name              => 'FlatNet',
      :cidr              => '10.99.99.0/24',
      :network_protocol  => 'ipv4',
      :cloud_tenant_id   => CloudTenant.find_by(:ems_ref => tenant_ref1).id,
      :type              => 'ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet::L2',
      :network_router_id => nil
    )

    s2 = CloudSubnet.find_by(:ems_ref => l2_subnet_ref2)
    expect(s2).to have_attributes(
      :name              => 'L2Un',
      :cidr              => nil,
      :network_protocol  => '',
      :cloud_tenant_id   => CloudTenant.find_by(:ems_ref => tenant_ref2).id,
      :type              => 'ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet::L2',
      :network_router_id => nil
    )
  end

  def assert_floating_ips
    ip = FloatingIp.find_by(:ems_ref => floating_ip_ref)
    expect(ip).to have_attributes(
      :address         => '10.85.92.109',
      :cloud_tenant_id => CloudTenant.find_by(:ems_ref => tenant_ref2).id,
      :type            => 'ManageIQ::Providers::Nuage::NetworkManager::FloatingIp'
    )
    router = NetworkRouter.find_by(:ems_ref => router_ref)
    expect(ip.network_router).to eq(router)
    expect(router.floating_ips).to include(ip)
  end

  def assert_cloud_networks
    net = CloudNetwork.find_by(:ems_ref => network_ref)
    expect(net).to have_attributes(
      :name => 'Subnet 0',
      :cidr => '10.85.92.0/24',
      :type => 'ManageIQ::Providers::Nuage::NetworkManager::CloudNetwork::Floating'
    )
    expect(net.floating_ips).to include(FloatingIp.find_by(:ems_ref => floating_ip_ref))
  end

  def assert_network_ports
    container_port = NetworkPort.find_by(:ems_ref => cont_port_ref)
    expect(container_port).to have_attributes(
      :name            => 'Container VPort 1ea3d199',
      :type            => 'ManageIQ::Providers::Nuage::NetworkManager::NetworkPort::Container',
      :floating_ip     => nil,
      :security_groups => [SecurityGroup.find_by(:ems_ref => security_group_ref)],
      :cloud_tenant    => CloudTenant.find_by(:ems_ref => tenant_ref2)
    )
    expect(container_port.cloud_subnet_network_ports.size).to eq(1)
    expect(container_port.cloud_subnet_network_ports.first).to have_attributes(
      :cloud_subnet => CloudSubnet.find_by(:ems_ref => cloud_subnet_ref1),
      :network_port => container_port,
      :address      => '10.98.80.100'
    )

    vm_port = NetworkPort.find_by(:ems_ref => vm_port_ref)
    expect(vm_port).to have_attributes(
      :name            => 'VM VPort 70e41192',
      :type            => 'ManageIQ::Providers::Nuage::NetworkManager::NetworkPort::Vm',
      :floating_ip     => nil,
      :security_groups => [SecurityGroup.find_by(:ems_ref => security_group_ref)],
      :cloud_tenant    => CloudTenant.find_by(:ems_ref => tenant_ref2)
    )
    expect(vm_port.cloud_subnet_network_ports.size).to eq(1)
    expect(vm_port.cloud_subnet_network_ports.first).to have_attributes(
      :cloud_subnet => CloudSubnet.find_by(:ems_ref => cloud_subnet_ref1),
      :network_port => vm_port,
      :address      => '10.98.78.179'
    )

    # Check VM was cross-provider connected
    expect(vm_port.device).to eq(vm_amazon)

    bridge_port = NetworkPort.find_by(:ems_ref => bridge_port_ref)
    expect(bridge_port).to have_attributes(
      :name            => 'Bridge VPort ad817d5a',
      :type            => 'ManageIQ::Providers::Nuage::NetworkManager::NetworkPort::Bridge',
      :floating_ip     => nil,
      :security_groups => [SecurityGroup.find_by(:ems_ref => security_group_ref)],
      :cloud_tenant    => CloudTenant.find_by(:ems_ref => tenant_ref2)
    )
    expect(bridge_port.cloud_subnet_network_ports.size).to eq(1)
    expect(bridge_port.cloud_subnet_network_ports.first).to have_attributes(
      :cloud_subnet => CloudSubnet.find_by(:ems_ref => cloud_subnet_ref1),
      :network_port => bridge_port,
      :address      => nil
    )

    host_port = NetworkPort.find_by(:ems_ref => host_port_ref)
    expect(host_port).to have_attributes(
      :name            => 'Host VPort 25772231',
      :type            => 'ManageIQ::Providers::Nuage::NetworkManager::NetworkPort::Host',
      :floating_ip     => FloatingIp.find_by(:ems_ref => floating_ip_ref),
      :security_groups => [SecurityGroup.find_by(:ems_ref => security_group_ref)],
      :cloud_tenant    => CloudTenant.find_by(:ems_ref => tenant_ref2)
    )
    expect(host_port.cloud_subnet_network_ports.size).to eq(1)
    expect(host_port.cloud_subnet_network_ports.first).to have_attributes(
      :cloud_subnet => CloudSubnet.find_by(:ems_ref => cloud_subnet_ref1),
      :network_port => host_port,
      :address      => '10.98.77.179'
    )
  end
end
