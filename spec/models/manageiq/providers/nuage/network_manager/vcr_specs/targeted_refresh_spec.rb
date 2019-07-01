describe ManageIQ::Providers::Nuage::NetworkManager::Refresher do
  TARGET_REFRESH_SETTINGS = [
    {
      :inventory_object_refresh => true,
      :allow_targeted_refresh   => true,
      :inventory_collections    => {
        :saver_strategy => :default,
      },
    },
    {
      :inventory_object_refresh => true,
      :allow_targeted_refresh   => true,
      :inventory_collections    => {
        :saver_strategy => :batch,
        :use_ar_object  => true,
      },
    },
    {
      :inventory_object_refresh => true,
      :allow_targeted_refresh   => true,
      :inventory_collections    => {
        :saver_strategy => :batch,
        :use_ar_object  => false,
      },
    },
    {
      :inventory_object_saving_strategy => :recursive,
      :inventory_object_refresh         => true,
      :allow_targeted_refresh           => true,
    }
  ].freeze

  before(:each) do
    @ems = FactoryBot.create(:ems_nuage_with_vcr_authentication, :port => 8443, :api_version => "v5_0", :security_protocol => "ssl-with-validation")
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

  describe "targeted refresh" do
    let(:tenant_ref)           { "e0819464-e7fc-4a37-b29a-e72da7b5956c" }
    let(:security_group_ref)   { "02e072ef-ca95-4164-856d-3ff177b9c13c" }
    let(:cloud_subnet_ref1)    { "d60d316a-c1ac-4412-813c-9652bdbc4e41" }
    let(:cloud_subnet_ref2)    { "debb9f88-f252-4c30-9a17-d6ae3865e365" }
    let(:unexisting_ref)       { "unexisting-ems-ref" }
    let(:router_ref)           { "75ad8ee8-726c-4950-94bc-6a5aab64631d" }
    let(:network_floating_ref) { "17b305a7-eec9-4492-acb9-20a1d63a8ba1" }
    let(:l2_cloud_subnet_ref)  { "3b733a41-774d-4aaa-8e64-588d5533a5c0" }
    let(:floating_ip_ref)      { "74d35a65-7fd0-454d-b78a-f58bf609f6b1" }
    let(:cont_port_ref)        { "dd9a4d57-2e24-427b-8aef-4d2925df47b2" }
    let(:vm_port_ref)          { "15d1369e-9553-4e83-8bb9-3a6c269f81ae" }
    let(:bridge_port_ref)      { "43b7faad-2c76-4945-9412-66a04bde7b6a" }
    let(:host_port_ref)        { "b19075d3-a797-4dcd-93be-de52b4247e46" }
    let(:vports_parent_ref)    { "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" }
    let(:network_router_ref)   { "b0edd930-2b74-44c4-8ea8-00f711cee619" }
    let(:subnet_template_ref)  { "bbbbbbbb-cccc-dddd-eeee-eeeeeeeeeeee" }
    let(:zone_template_ref)    { "abababab-abab-abab-abab-abababababab" }
    let(:zone_ref)             { "babababa-baba-baba-baba-babababababa" }

    TARGET_REFRESH_SETTINGS.each do |settings|
      context "with settings #{settings}" do
        before(:each) do
          stub_settings_merge(
            :ems_refresh => {
              :nuage_network => settings
            }
          )
        end

        describe "on empty database" do
          it "will refresh cloud_subnet" do
            cloud_subnet = FactoryBot.build(:cloud_subnet_l3_nuage, :ems_ref => cloud_subnet_ref1)
            test_targeted_refresh([cloud_subnet], 'cloud_subnet') do
              assert_cloud_subnet_counts
              assert_specific_cloud_subnet
            end
          end

          it "will refresh cloud tenant" do
            tenant = FactoryBot.build(:cloud_tenant_nuage, :ems_ref => tenant_ref)
            test_targeted_refresh([tenant], 'cloud_tenant') do
              assert_cloud_tenant_counts
              assert_specific_cloud_tenant
            end
          end

          it "will refresh security_group" do
            security_group = FactoryBot.build(:security_group_nuage, :ems_ref => security_group_ref)
            test_targeted_refresh([security_group], 'security_group') do
              assert_security_group_counts
              assert_specific_security_group
            end
          end

          it "will refresh cloud_network_floating" do
            network_floating = FactoryBot.build(:cloud_network_floating_nuage, :ems_ref => network_floating_ref)
            test_targeted_refresh([network_floating], 'cloud_network_floating') do
              assert_specific_cloud_network_floating
            end
          end

          it "will refresh l2_cloud_subnets" do
            l2_cloud_subnet = FactoryBot.build(:cloud_subnet_l2_nuage, :ems_ref => l2_cloud_subnet_ref)
            test_targeted_refresh([l2_cloud_subnet], 'l2_cloud_subnet') do
              assert_specific_l2_cloud_subnet
            end
          end

          it "will refresh floating_ip" do
            floating_ip = FactoryBot.build(:floating_ip_nuage, :ems_ref => floating_ip_ref)
            test_targeted_refresh([floating_ip], 'floating_ip') do
              assert_specific_floating_ip
            end
          end

          it "will refresh network_router" do
            network_router = FactoryBot.build(:network_router_nuage, :ems_ref => network_router_ref)
            test_targeted_refresh([network_router], 'network_router', :options => { :operation => 'CREATE' }) do
              assert_specific_network_router
            end
          end

          describe "will refresh network_port" do
            before do
              FactoryBot.create(:cloud_subnet_l3_nuage, :ems_ref => vports_parent_ref, :ems_id => @ems.id)
            end

            it "bridge" do
              port = FactoryBot.build(:network_port_bridge_nuage, :ems_ref => bridge_port_ref)
              test_targeted_refresh([port], 'network_port_bridge') do
                assert_specific_network_port_bridge
              end
            end

            it "container" do
              port = FactoryBot.build(:network_port_container_nuage, :ems_ref => cont_port_ref)
              test_targeted_refresh([port], 'network_port_container') do
                assert_specific_network_port_container
              end
            end

            it "host" do
              port = FactoryBot.build(:network_port_host_nuage, :ems_ref => host_port_ref)
              test_targeted_refresh([port], 'network_port_host') do
                assert_specific_network_port_host
              end
            end

            it "vm" do
              port = FactoryBot.build(:network_port_vm_nuage, :ems_ref => vm_port_ref)
              test_targeted_refresh([port], 'network_port_vm') do
                assert_specific_network_port_vm
              end
            end
          end
        end

        describe "on populated database" do
          context "object updated on remote server" do
            let!(:cloud_tenant) do
              FactoryBot.create(:cloud_tenant_nuage, :ems_id => @ems.id, :ems_ref => tenant_ref, :name => nil)
            end

            let!(:cloud_subnet) do
              FactoryBot.create(:cloud_subnet_l3_nuage, :ems_id => @ems.id, :ems_ref => cloud_subnet_ref1,
                                 :cloud_tenant => cloud_tenant, :name => nil)
            end

            let!(:security_group) do
              FactoryBot.create(:security_group_nuage, :ems_id => @ems.id, :ems_ref => security_group_ref,
                                 :cloud_tenant => cloud_tenant, :name => nil)
            end

            let!(:network_floating) do
              FactoryBot.create(:cloud_network_floating_nuage, :ems_id => @ems.id, :ems_ref => network_floating_ref,
                                 :name => nil)
            end

            let!(:l2_cloud_subnet) do
              FactoryBot.create(:cloud_subnet_l2_nuage, :ems_id => @ems.id, :ems_ref => l2_cloud_subnet_ref,
                                 :name => nil)
            end

            let!(:floating_ip) do
              FactoryBot.create(:floating_ip_nuage, :ems_id => @ems.id, :ems_ref => floating_ip_ref,
                                 :address => nil)
            end

            let!(:network_port) do
              FactoryBot.create(:network_port_bridge_nuage, :ems_id => @ems.id, :ems_ref => bridge_port_ref,
                                 :name => nil)
            end

            let!(:network_router) do
              FactoryBot.create(:network_router_nuage, :ems_id => @ems.id, :ems_ref => network_router_ref,
                                 :name => nil)
            end

            it "cloud_tenant is updated" do
              test_targeted_refresh([cloud_tenant], 'cloud_tenant_is_updated') do
                assert_fetched(cloud_tenant)
              end
            end

            it "cloud_subnet is updated" do
              test_targeted_refresh([cloud_subnet], 'cloud_subnet_is_updated') do
                assert_fetched(cloud_subnet)
              end
            end

            it "security_group is updated" do
              test_targeted_refresh([security_group], 'security_group_is_updated') do
                assert_fetched(security_group)
              end
            end

            it "cloud_network_floating is updated" do
              test_targeted_refresh([network_floating], 'cloud_network_floating_is_updated') do
                assert_fetched(network_floating)
              end
            end

            it "l2_cloud_subnet is updated" do
              test_targeted_refresh([l2_cloud_subnet], 'l2_cloud_subnet_is_updated') do
                assert_fetched(l2_cloud_subnet)
              end
            end

            it "floating_ip is updated" do
              test_targeted_refresh([floating_ip], 'floating_ip_is_updated') do
                assert_fetched(floating_ip, :attribute => :address)
              end
            end

            it "network_port is updated" do
              test_targeted_refresh([network_port], 'network_port_is_updated') do
                assert_fetched(network_port)
              end
            end

            it "network_router is updated" do
              test_targeted_refresh([network_router], 'network_router_is_updated') do
                assert_fetched(network_router)
              end
            end
          end

          context "object no longer exists on remote server" do
            let(:cloud_tenant)     { FactoryBot.create(:cloud_tenant_nuage, :ems_id => @ems.id, :ems_ref => unexisting_ref) }
            let(:cloud_subnet)     { FactoryBot.create(:cloud_subnet_l3_nuage, :ems_id => @ems.id, :ems_ref => unexisting_ref, :cloud_tenant => cloud_tenant) }
            let(:security_group)   { FactoryBot.create(:security_group_nuage, :ems_id => @ems.id, :ems_ref => unexisting_ref, :cloud_tenant => cloud_tenant) }
            let(:network_floating) { FactoryBot.create(:cloud_network_floating_nuage, :ems_id => @ems.id, :ems_ref => unexisting_ref) }
            let(:l2_cloud_subnet)  { FactoryBot.create(:cloud_subnet_l2_nuage, :ems_id => @ems.id, :ems_ref => unexisting_ref, :cloud_tenant => cloud_tenant) }
            let(:floating_ip)      { FactoryBot.create(:floating_ip_nuage, :ems_id => @ems.id, :ems_ref => unexisting_ref, :cloud_tenant => cloud_tenant) }
            let(:network_port)     { FactoryBot.create(:network_port_bridge_nuage, :ems_id => @ems.id, :ems_ref => unexisting_ref, :cloud_tenant => cloud_tenant) }
            let(:network_router)   { FactoryBot.create(:network_router_nuage, :ems_id => @ems.id, :ems_ref => unexisting_ref, :cloud_tenant => cloud_tenant) }

            it "unexisting cloud_tenant is deleted" do
              test_targeted_refresh([cloud_tenant], 'cloud_tenant_is_deleted', :repeat => 1) do
                assert_deleted(cloud_tenant)
              end
            end

            it "unexisting cloud_subnet is deleted, but related cloud_tenant and security_group updated" do
              test_targeted_refresh([cloud_subnet], 'cloud_subnet_is_deleted', :repeat => 1) do
                assert_deleted(cloud_subnet)
              end
            end

            it "unexisting security_group is deleted, but related cloud_tenant updated" do
              test_targeted_refresh([security_group], 'security_group_is_deleted', :repeat => 1) do
                assert_deleted(security_group)
              end
            end

            it "unexisting cloud_network_floating is deleted" do
              test_targeted_refresh([network_floating], 'cloud_network_floating_is_deleted', :repeat => 1) do
                assert_deleted(network_floating)
              end
            end

            it "unexisting l2_cloud_subnet is deleted" do
              test_targeted_refresh([l2_cloud_subnet], 'l2_cloud_subnet_is_deleted', :repeat => 1) do
                assert_deleted(l2_cloud_subnet)
              end
            end

            it "unexisting floating_ip is deleted" do
              test_targeted_refresh([floating_ip], 'floating_ip_is_deleted', :repeat => 1) do
                assert_deleted(floating_ip)
              end
            end

            it "unexisting network_port is deleted" do
              test_targeted_refresh([network_port], 'network_port_is_deleted', :repeat => 1) do
                assert_deleted(network_port)
              end
            end

            it "unexisting network_router is deleted" do
              test_targeted_refresh([network_router], 'network_router_is_deleted', :repeat => 1) do
                assert_deleted(network_router)
              end
            end

            it "cloud_subnet is deleted when its template is deleted" do
              cloud_subnet.tap { |subnet| subnet.extra_attributes = { 'template_id' => subnet_template_ref } }.save
              subnet_template = InventoryRefresh::Target.new(
                :manager     => @ems,
                :association => :cloud_subnet_templates,
                :manager_ref => { :ems_ref => subnet_template_ref },
                :options     => { :operation => 'DELETE' }
              )
              test_targeted_refresh([subnet_template], 'no_api_interaction', :repeat => 1) do
                assert_deleted(cloud_subnet)
              end
            end

            it "cloud_subnet is deleted when its zone template is deleted" do
              cloud_subnet.tap { |subnet| subnet.extra_attributes = { 'zone_template_id' => zone_template_ref } }.save
              zone_template = InventoryRefresh::Target.new(
                :manager     => @ems,
                :association => :zone_templates,
                :manager_ref => { :ems_ref => zone_template_ref },
                :options     => { :operation => 'DELETE' }
              )
              test_targeted_refresh([zone_template], 'no_api_interaction', :repeat => 1) do
                assert_deleted(cloud_subnet)
              end
            end

            it "cloud_subnet is deleted when its zone is deleted" do
              cloud_subnet.tap { |subnet| subnet.extra_attributes = { 'zone_id' => zone_ref } }.save
              zone = InventoryRefresh::Target.new(
                :manager     => @ems,
                :association => :zones,
                :manager_ref => { :ems_ref => zone_ref },
                :options     => { :operation => 'DELETE' }
              )
              test_targeted_refresh([zone], 'no_api_interaction', :repeat => 1) do
                assert_deleted(cloud_subnet)
              end
            end

            it "security_group is deleted if its network_router is deleted" do
              security_group.tap { |group| group.network_router = network_router }.save
              test_targeted_refresh([network_router], 'network_router_is_deleted', :repeat => 1) do
                assert_deleted(network_router)
                assert_deleted(security_group)
              end
            end

            it "security_group is deleted if its cloud_subnet is deleted" do
              security_group.tap { |group| group.cloud_subnet = cloud_subnet }.save
              test_targeted_refresh([cloud_subnet], 'cloud_subnet_is_deleted', :repeat => 1) do
                assert_deleted(cloud_subnet)
                assert_deleted(security_group)
              end
            end
          end
        end
      end
    end
  end

  def test_targeted_refresh(targets, cassette, repeat: 2, options: {})
    targets = active_records_to_targets(targets, :options => options)
    repeat.times do # Run twice to verify that a second run with existing data does not change anything
      EmsRefresh.queue_refresh(targets)
      expect(MiqQueue.where(:method_name => 'refresh').count).to eq 1
      refresh_job = MiqQueue.where(:method_name => 'refresh').first
      VCR.use_cassette(described_class.name.underscore + "_targeted/" + cassette) do
        status, msg, _ = refresh_job.deliver
        expect(:status => status, :msg => msg).not_to include(:status => 'error')
      end
      @ems.reload
      yield
    end
  end

  def active_records_to_targets(targets, options: {})
    targets.map do |target|
      case target
      when InventoryRefresh::Target
        return target
      when CloudTenant
        association = :cloud_tenants
      when ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet::L3
        association = :cloud_subnets
        options     = options.merge(:kind => 'L3')
      when ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet::L2
        association = :cloud_subnets
        options     = options.merge(:kind => 'L2')
      when SecurityGroup
        association = :security_groups
      when CloudNetwork
        association = :cloud_networks
      when FloatingIp
        association = :floating_ips
      when NetworkPort
        association = :network_ports
      when NetworkRouter
        association = :network_routers
      end
      InventoryRefresh::Target.new(
        :manager     => @ems,
        :association => association,
        :manager_ref => {:ems_ref => target.ems_ref},
        :options     => options
      )
    end
  end

  def assert_cloud_subnet_counts
    expect(ExtManagementSystem.count).to eq(2)
    expect(CloudTenant.count).to eq(0)
    expect(SecurityGroup.count).to eq(0)
    expect(CloudSubnet.count).to eq(1)
    expect(FloatingIp.count).to eq(0)
    expect(NetworkPort.count).to eq(0)
    expect(NetworkRouter.count).to eq(0)
  end

  def assert_specific_cloud_subnet
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
      :cloud_tenant_id                => nil,
      :dns_nameservers                => nil,
      :ipv6_router_advertisement_mode => nil,
      :ipv6_address_mode              => nil,
      :type                           => "ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet::L3",
      :network_router_id              => nil,
      :parent_cloud_subnet_id         => nil,
      :extra_attributes               => {
        "domain_id"        => "75ad8ee8-726c-4950-94bc-6a5aab64631d",
        "zone_name"        => "Zone 1",
        "zone_id"          => "6256954b-9dd6-43ed-94ff-9daa683ab8b0",
        "template_id"      => nil,
        "zone_template_id" => nil
      }
    )
  end

  def assert_cloud_tenant_counts
    expect(ExtManagementSystem.count).to eq(2)
    expect(CloudTenant.count).to eq(1)
    expect(SecurityGroup.count).to eq(0)
    expect(CloudSubnet.count).to eq(0)
    expect(FloatingIp.count).to eq(0)
    expect(NetworkPort.count).to eq(0)
    expect(NetworkRouter.count).to eq(0)
  end

  def assert_specific_cloud_tenant
    g = CloudTenant.find_by(:ems_ref => tenant_ref)
    expect(g).to have_attributes(
      :name   => "XLAB",
      :ems_id => @ems.id,
      :type   => "ManageIQ::Providers::Nuage::NetworkManager::CloudTenant"
    )
    expect(g.cloud_subnets.count).to eq(0)
    expect(g.security_groups.count).to eq(0)
  end

  def assert_security_group_counts
    expect(ExtManagementSystem.count).to eq(2)
    expect(CloudTenant.count).to eq(0)
    expect(SecurityGroup.count).to eq(1)
    expect(CloudSubnet.count).to eq(0)
    expect(FloatingIp.count).to eq(0)
    expect(NetworkPort.count).to eq(0)
    expect(NetworkRouter.count).to eq(0)
  end

  def assert_specific_security_group
    g1 = SecurityGroup.find_by(:ems_ref => security_group_ref)
    expect(g1).to have_attributes(
      :name                   => "Test Policy Group",
      :description            => nil,
      :type                   => "ManageIQ::Providers::Nuage::NetworkManager::SecurityGroup",
      :ems_id                 => @ems.id,
      :cloud_network_id       => nil,
      :cloud_tenant_id        => nil,
      :orchestration_stack_id => nil
    )
  end

  def assert_specific_cloud_network_floating
    n = CloudNetwork.find_by(:ems_ref => network_floating_ref)
    expect(n).to have_attributes(
      :name   => "Subnet 0",
      :type   => "ManageIQ::Providers::Nuage::NetworkManager::CloudNetwork::Floating",
      :ems_id => @ems.id,
      :cidr   => '10.85.92.0/24'
    )
  end

  def assert_specific_l2_cloud_subnet
    s = CloudSubnet.find_by(:ems_ref => l2_cloud_subnet_ref)
    expect(s).to have_attributes(
      :name             => "FlatNet",
      :ems_id           => @ems.id,
      :cidr             => "10.99.99.0/24",
      :gateway          => nil,
      :network_protocol => "ipv4",
      :cloud_tenant_id  => nil,
      :type             => "ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet::L2",
      :extra_attributes => nil
    )
  end

  def assert_specific_floating_ip
    s = FloatingIp.find_by(:ems_ref => floating_ip_ref)
    expect(s).to have_attributes(
      :address => '10.85.92.128',
      :ems_id  => @ems.id
    )
  end

  def assert_specific_network_port_bridge
    port = NetworkPort.find_by(:ems_ref => bridge_port_ref)
    expect(port).to have_attributes(
      :name   => 'Bridge VPort ad817d5a',
      :ems_id => @ems.id,
      :type   => 'ManageIQ::Providers::Nuage::NetworkManager::NetworkPort::Bridge'
    )
  end

  def assert_specific_network_port_container
    port = NetworkPort.find_by(:ems_ref => cont_port_ref)
    expect(port).to have_attributes(
      :name   => 'Container VPort 1ea3d199',
      :ems_id => @ems.id,
      :type   => 'ManageIQ::Providers::Nuage::NetworkManager::NetworkPort::Container'
    )
  end

  def assert_specific_network_port_host
    port = NetworkPort.find_by(:ems_ref => host_port_ref)
    expect(port).to have_attributes(
      :name   => 'Host VPort 25772231',
      :ems_id => @ems.id,
      :type   => 'ManageIQ::Providers::Nuage::NetworkManager::NetworkPort::Host'
    )
  end

  def assert_specific_network_port_vm
    port = NetworkPort.find_by(:ems_ref => vm_port_ref)
    expect(port).to have_attributes(
      :name   => 'VM VPort 70e41192',
      :ems_id => @ems.id,
      :type   => 'ManageIQ::Providers::Nuage::NetworkManager::NetworkPort::Vm'
    )
  end

  def assert_specific_network_router
    router = NetworkRouter.find_by(:ems_ref => network_router_ref)
    expect(router).to have_attributes(
      :name   => 'Routy',
      :ems_id => @ems.id,
      :type   => 'ManageIQ::Providers::Nuage::NetworkManager::NetworkRouter'
    )
    # Verify that we've fetched subnets as well upon router creation because
    # there is a glitch in Nuage that no extra events are emitted for those.
    expect(router.cloud_subnets.size).to eq(3)
  end

  def assert_fetched(instance, attribute: :name)
    instance.reload
    expect(instance.try(attribute).to_s).not_to be_empty
  end

  def assert_not_fetched(instance)
    instance.reload
    expect(instance.name.to_s).to be_empty
  end

  def assert_deleted(instance)
    expect { instance.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
