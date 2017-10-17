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

  describe "targeted refresh" do
    let(:network_group_ref)  { "e0819464-e7fc-4a37-b29a-e72da7b5956c" }
    let(:security_group_ref) { "02e072ef-ca95-4164-856d-3ff177b9c13c" }
    let(:cloud_subnet_ref1)  { "d60d316a-c1ac-4412-813c-9652bdbc4e41" }
    let(:cloud_subnet_ref2)  { "debb9f88-f252-4c30-9a17-d6ae3865e365" }
    let(:unexisting_ref)     { "unexisting-ems-ref" }

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
            cloud_subnet = FactoryGirl.build(:cloud_subnet_nuage, :ems_ref => cloud_subnet_ref1)
            test_targeted_refresh([cloud_subnet], 'cloud_subnet') do
              assert_cloud_subnet_counts
              assert_specific_cloud_subnet
            end
          end

          it "will refresh network_group" do
            network_group = FactoryGirl.build(:network_group_nuage, :ems_ref => network_group_ref)
            test_targeted_refresh([network_group], 'network_group') do
              assert_network_group_counts
              assert_specific_network_group
            end
          end

          it "will refresh security_group" do
            security_group = FactoryGirl.build(:security_group_nuage, :ems_ref => security_group_ref)
            test_targeted_refresh([security_group], 'security_group') do
              assert_security_group_counts
              assert_specific_security_group
            end
          end
        end

        describe "on populated database" do
          context "object updated on remote server" do
            let!(:network_group) do
              FactoryGirl.create(:network_group_nuage, :ems_id => @ems.id, :ems_ref => network_group_ref, :name => nil)
            end

            let!(:cloud_subnet) do
              FactoryGirl.create(:cloud_subnet_nuage, :ems_id => @ems.id, :ems_ref => cloud_subnet_ref1,
                                 :network_group => network_group, :name => nil)
            end

            let!(:security_group) do
              FactoryGirl.create(:security_group_nuage, :ems_id => @ems.id, :ems_ref => security_group_ref,
                                 :network_group => network_group, :name => nil)
            end

            it "network_group is updated" do
              test_targeted_refresh([network_group], 'network_group_is_updated') do
                assert_fetched(network_group)
                assert_fetched(cloud_subnet)
                assert_fetched(security_group)
              end
            end

            it "cloud_subnet is updated" do
              test_targeted_refresh([cloud_subnet], 'cloud_subnet_is_updated') do
                assert_fetched(network_group)
                assert_fetched(cloud_subnet)
                assert_fetched(security_group)
              end
            end

            it "security_group is updated" do
              test_targeted_refresh([security_group], 'security_group_is_updated') do
                assert_fetched(network_group)
                assert_not_fetched(cloud_subnet)
                assert_fetched(security_group)
              end
            end
          end

          context "object no longer exists on remote server" do
            it "unexisting network_group is deleted" do
              network_group = FactoryGirl.create(:network_group_nuage, :ems_id => @ems.id, :ems_ref => unexisting_ref)
              cloud_subnet = FactoryGirl.create(:cloud_subnet_nuage, :ems_id => @ems.id, :ems_ref => unexisting_ref, :network_group => network_group)
              security_group = FactoryGirl.create(:security_group_nuage, :ems_id => @ems.id, :ems_ref => unexisting_ref, :network_group => network_group)
              test_targeted_refresh([network_group], 'network_group_is_deleted', :repeat => 1) do
                assert_deleted(network_group)
                assert_deleted(cloud_subnet)
                assert_deleted(security_group)
              end
            end

            it "unexisting cloud_subnet is deleted, but related network_group and security_group updated" do
              network_group = FactoryGirl.create(:network_group_nuage, :ems_id => @ems.id, :ems_ref => network_group_ref)
              cloud_subnet = FactoryGirl.create(:cloud_subnet_nuage, :ems_id => @ems.id, :ems_ref => unexisting_ref, :network_group => network_group)
              security_group = FactoryGirl.create(:security_group_nuage, :ems_id => @ems.id, :ems_ref => security_group_ref, :network_group => network_group)
              test_targeted_refresh([cloud_subnet], 'cloud_subnet_is_deleted', :repeat => 1) do
                assert_fetched(network_group)
                assert_deleted(cloud_subnet)
                assert_fetched(security_group)
              end
            end

            it "unexisting security_group is deleted, but related network_group updated" do
              network_group = FactoryGirl.create(:network_group_nuage, :ems_id => @ems.id, :ems_ref => network_group_ref)
              security_group = FactoryGirl.create(:security_group_nuage, :ems_id => @ems.id, :ems_ref => unexisting_ref, :network_group => network_group)
              test_targeted_refresh([security_group], 'security_group_is_deleted', :repeat => 1) do
                assert_fetched(network_group)
                assert_deleted(security_group)
              end
            end
          end
        end
      end
    end
  end

  def test_targeted_refresh(targets, cassette, repeat: 2)
    targets = active_records_to_targets(targets)
    repeat.times do # Run twice to verify that a second run with existing data does not change anything
      EmsRefresh.queue_refresh(targets)
      expect(MiqQueue.where(:method_name => 'refresh').count).to eq 1
      refresh_job = MiqQueue.where(:method_name => 'refresh').first
      VCR.use_cassette(described_class.name.underscore + "_targeted/" + cassette) do
        refresh_job.deliver
      end
      @ems.reload
      yield
    end
  end

  def active_records_to_targets(targets)
    targets.map do |target|
      case target
      when ManagerRefresh::Target
        return target
      when NetworkGroup
        association = :network_groups
      when CloudSubnet
        association = :cloud_subnets
      when SecurityGroup
        association = :security_groups
      end
      ManagerRefresh::Target.new(
        :manager     => @ems,
        :association => association,
        :manager_ref => {:ems_ref => target.ems_ref}
      )
    end
  end

  def assert_cloud_subnet_counts
    expect(ExtManagementSystem.count).to eq(1)
    expect(NetworkGroup.count).to eq(1)
    expect(SecurityGroup.count).to eq(1)
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
      :type                           => "ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet",
      :network_router_id              => nil,
      :network_group_id               => NetworkGroup.find_by(:ems_ref => network_group_ref).id,
      :parent_cloud_subnet_id         => nil,
      :extra_attributes               => {
        "enterprise_name" => "XLAB",
        "enterprise_id"   => network_group_ref,
        "domain_name"     => "BaseL3",
        "domain_id"       => "75ad8ee8-726c-4950-94bc-6a5aab64631d",
        "zone_name"       => "Zone 1",
        "zone_id"         => "6256954b-9dd6-43ed-94ff-9daa683ab8b0"
      }
    )
  end

  def assert_network_group_counts
    expect(ExtManagementSystem.count).to eq(1)
    expect(NetworkGroup.count).to eq(1)
    expect(SecurityGroup.count).to eq(1)
    expect(CloudSubnet.count).to eq(2)
    expect(FloatingIp.count).to eq(0)
    expect(NetworkPort.count).to eq(0)
    expect(NetworkRouter.count).to eq(0)
  end

  def assert_specific_network_group
    g = NetworkGroup.find_by(:ems_ref => network_group_ref)
    expect(g).to have_attributes(
      :name                   => "XLAB",
      :cidr                   => nil,
      :status                 => "active",
      :enabled                => nil,
      :ems_id                 => @ems.id,
      :orchestration_stack_id => nil,
      :type                   => "ManageIQ::Providers::Nuage::NetworkManager::NetworkGroup"
    )
    expect(g.cloud_subnets.count).to eq(2)
    expect(g.security_groups.count).to eq(1)

    expect(g.cloud_subnets.map(&:ems_ref))
      .to match_array([cloud_subnet_ref1, cloud_subnet_ref2])
    expect(g.security_groups.map(&:ems_ref))
      .to match_array([security_group_ref])
  end

  def assert_security_group_counts
    expect(ExtManagementSystem.count).to eq(1)
    expect(NetworkGroup.count).to eq(1)
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
    expect(g1.network_group.ems_ref).to eq(network_group_ref)
  end

  def assert_fetched(instance)
    instance.reload
    expect(instance.name.to_s).not_to be_empty
  end

  def assert_not_fetched(instance)
    instance.reload
    expect(instance.name.to_s).to be_empty
  end

  def assert_deleted(instance)
    expect { instance.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
