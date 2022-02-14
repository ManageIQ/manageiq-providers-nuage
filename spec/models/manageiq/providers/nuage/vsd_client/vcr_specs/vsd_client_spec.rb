require 'date'
describe ManageIQ::Providers::Nuage::NetworkManager::VsdClient do
  include Vmdb::Logging

  UUID_REGEXP = /([0-9a-z]{8})-(([0-9a-z]{4})-){3}([0-9a-z]{12})/
  ROUTE_PROPERTY_REGEXP = /([0-9]{5}):([0-9a-z]{4,5})/
  IP_ADDR_REGEXP = /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/
  MAC_ADDR_REGEXP = /^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/

  ENTERPRISE_ID = '6abac3ad-a05d-4b93-9556-4ba5010fb13b'.freeze
  DOMAIN_ID = 'd0c3274c-397a-4173-8981-bfd2f99ef8c6'.freeze
  ZONE_ID = '76ac549a-5843-4f1b-ac90-b21ff6edc2a4'.freeze
  SUBNET_ID = '4da803f7-c0d2-4beb-b02e-341ea77e377f'.freeze
  POLICY_GROUP_ID = 'fadd09c4-9fea-46ec-8342-73f1b6a4df74'.freeze

  let(:userid) { Rails.application.secrets.nuage[:userid] }
  let(:password) { Rails.application.secrets.nuage[:password] }
  let(:hostname) { Rails.application.secrets.nuage[:host] }

  def vcr_play(cassette, method, args: [])
    VCR.use_cassette("#{described_class.module_parent.name.underscore}/vsd_client/#{cassette}") do
      @vsd_client.send(method, *args)
    end
  end

  context "when login successful" do
    before(:each) do
      VCR.use_cassette(described_class.module_parent.name.underscore + '/vsd_client/login') do
        @vsd_client = described_class.new("https://#{hostname}:8443/nuage/api/v5_0", userid, password)
      end
    end

    it "should return valid non empty response for get_enterprises" do
      enterprises = vcr_play('enterprises', :get_enterprises)
      assert_object_not_empty(enterprises)
      assert_enterprises(enterprises)
    end

    it "should return valid non empty response for get_enterprise by id" do
      enterprise = vcr_play('enterprise', :get_enterprise, :args => ENTERPRISE_ID)
      assert_object_not_empty(enterprise)
      assert_enterprise(enterprise)
    end

    it "should return valid non empty response for domains" do
      domains = vcr_play('domains', :get_domains)
      assert_object_not_empty(domains)
      assert_domains(domains)
    end

    it "should return valid non empty response for domain by id" do
      domain = vcr_play('domain', :get_domain, :args => DOMAIN_ID)
      assert_object_not_empty(domain)
      assert_domain(domain)
    end

    it "should return valid non empty response for domains for enterprise_id" do
      domains = vcr_play('domains_for_enterprise_id', :get_domains_for_enterprise, :args => ENTERPRISE_ID)
      assert_object_not_empty(domains)
      assert_domains(domains)
    end

    it "should return valid non empty response for zones" do
      zones = vcr_play('zones', :get_zones)
      assert_object_not_empty(zones)
      assert_zones(zones)
    end

    it "should return valid non empty response for zone by id" do
      zone = vcr_play('zone', :get_zone, :args => ZONE_ID)
      assert_object_not_empty(zone)
      assert_zone(zone)
    end

    it "should return valid non empty response for subnets" do
      subnets = vcr_play('subnets', :get_subnets)
      assert_object_not_empty(subnets)
      assert_subnets(subnets)
    end

    it "should return valid non empty response for subnet by id" do
      subnet = vcr_play('subnet', :get_subnet, :args=>SUBNET_ID)
      assert_object_not_empty(subnet)
      assert_subnet(subnet)
    end

    it "should return valid non empty response for subnets for domain" do
      subnets = vcr_play('subnets_for_domain', :get_subnets_for_domain, :args => DOMAIN_ID)
      assert_object_not_empty(subnets)
      assert_subnets(subnets)
    end

    it "should return valid non empty response for vms" do
      vms = vcr_play('vms', :get_vms)
      assert_object_not_empty(vms)
      assert_vms(vms)
    end

    it "should return valid non empty response for policy_groups" do
      policy_groups = vcr_play('policy_groups', :get_policy_groups)
      assert_object_not_empty(policy_groups)
      assert_policy_groups(policy_groups)
    end

    it "should return valid non empty response for policy_group by id" do
      policy_group = vcr_play('policy_group', :get_policy_group, :args => POLICY_GROUP_ID)
      assert_object_not_empty(policy_group)
      assert_policy_group(policy_group)
    end

    it "should return valid non empty response for policy_groups for domain" do
      policy_groups = vcr_play('policy_groups_for_domain', :get_policy_groups_for_domain, :args=>DOMAIN_ID)
      assert_object_not_empty(policy_groups)
      assert_policy_groups(policy_groups)
    end
  end

  context "when login fails" do
    it "should fail on wrong password" do
      VCR.use_cassette(described_class.module_parent.name.underscore + '/vsd_client/wrong_pass') do
        expect do
          described_class.new("https://#{hostname}:8443/nuage/api/v5_0", userid, 'wrong_password')
        end.to raise_error(MiqException::MiqInvalidCredentialsError)
      end
    end

    it "should fail on wrong username" do
      VCR.use_cassette(described_class.module_parent.name.underscore + '/vsd_client/wrong_user') do
        expect do
          described_class.new("https://#{hostname}:8443/nuage/api/v5_0", 'wrong_user', password)
        end.to raise_error(MiqException::MiqInvalidCredentialsError)
      end
    end

    it "should fail on wrong hostname" do
      VCR.use_cassette(described_class.module_parent.name.underscore + '/vsd_client/wrong_hostname') do
        expect do
          described_class.new("https://wronghost:8443/nuage/api/v5_0", userid, password)
        end.to raise_error(SocketError)
      end
    end
  end

  def assert_object_not_empty(object)
    expect(object.length).to be > 0
    expect(object.length).to be_truthy
  end

  def assert_enterprises(enterprises)
    expect(enterprises.count).to be > 0
    assert_enterprise(enterprises.first)
  end

  def assert_enterprise(enterprise)
    assert_time_fields(enterprise, %w(lastUpdatedDate creationDate))
    assert_identifier_fields(enterprise, %w(ID lastUpdatedBy owner enterpriseProfileID
                                            enterpriseProfileID receiveMultiCastListID
                                            associatedGroupKeyEncryptionProfileID
                                            associatedEnterpriseSecurityID associatedKeyServerMonitorID))
    assert_string_fields(enterprise, %w(name))
    assert_integer_fields(enterprise, %w(floatingIPsQuota floatingIPsUsed dictionaryVersion customerID))
    assert_boolean_property_fields(enterprise, %w(allowTrustedForwardingClass allowAdvancedQOSConfiguration
                                                  allowGatewayManagement enableApplicationPerformanceManagement
                                                  LDAPEnabled LDAPAuthorizationEnabled BGPEnabled))
    assert_entity_scope(enterprise['entityScope'])
    assert_enabled_disabled_inherited_fields(enterprise, %w(encryptionManagementMode))
  end

  def assert_domains(domains)
    expect(domains.count).to be > 0
    assert_domain(domains.first)
  end

  def assert_domain(domain)
    assert_time_fields(domain, %w(lastUpdatedDate creationDate))
    assert_identifier_fields(domain, %w(ID lastUpdatedBy owner parentID templateID enterpriseID))
    assert_string_fields(domain, %w(parentType name description))
    assert_integer_fields(domain, %w(backHaulVNID serviceID customerID labelID ECMPCount domainID domainVLANID))
    assert_boolean_property_fields(domain, %w(stretched globalRoutingEnabled leakingEnabled BGPEnabled))
    assert_entity_scope(domain['entityScope'])
    assert_route_property_fields(domain, %w(routeDistinguisher routeTarget backHaulRouteDistinguisher backHaulRouteTarget importRouteTarget exportRouteTarget))
    assert_enabled_disabled_inherited_fields(domain, %w(maintenanceMode underlayEnabled encryption multicast PATEnabled DPI))
  end

  def assert_zones(zones)
    expect(zones.count).to be > 0
    assert_zone(zones.first)
  end

  def assert_zone(zone)
    assert_time_fields(zone, %w(lastUpdatedDate creationDate))
    assert_identifier_fields(zone, %w(ID lastUpdatedBy owner parentID))
    assert_string_fields(zone, %w(parentType name))
    assert_integer_fields(zone, %w(numberOfHostsInSubnets policyGroupID))
    assert_boolean_property_fields(zone, %w(publicZone))
    assert_entity_scope(zone['entityScope'])
    assert_ip_type(zone['IPType'])
    assert_enabled_disabled_inherited_fields(zone, %w(maintenanceMode encryption multicast DPI))
  end

  def assert_subnets(subnets)
    expect(subnets.count).to be > 0
    assert_subnet(subnets.first)
  end

  def assert_subnet(subnet)
    assert_time_fields(subnet, %w(lastUpdatedDate creationDate))
    assert_identifier_fields(subnet, %w(ID lastUpdatedBy owner parentID))
    assert_string_fields(subnet, %w(parentType name))
    assert_integer_fields(subnet, %w(vnId serviceID policyGroupID))
    assert_boolean_property_fields(subnet, %w(underlay splitSubnet public proxyARP))
    assert_entity_scope(subnet['entityScope'])
    assert_ip_type(subnet['IPType'])
    assert_ip_fields(subnet, %w(address netmask gateway))
    assert_route_property_fields(subnet, %w(routeDistinguisher routeTarget))
    assert_enabled_disabled_inherited_fields(subnet, %w(maintenanceMode underlayEnabled
                                                        encryption PATEnabled DHCPRelayStatus
                                                        multicast DPI useGlobalMAC))
  end

  def assert_vms(vms)
    expect(vms.count).to be > 0
    assert_vm(vms.first)
  end

  def assert_vm(vm)
    assert_time_fields(vm, %w(lastUpdatedDate creationDate))
    assert_identifier_fields(vm, %w(ID lastUpdatedBy owner UUID enterpriseID userID))
    assert_string_fields(vm, %w(name enterpriseName userName status hypervisorIP))
    assert_integer_fields(vm, %w(deleteExpiry))
    assert_boolean_property_fields(vm, %w(computeProvisioned))
    assert_entity_scope(vm['entityScope'])

    assert_identifier_array(vm['domainIDs'])
    assert_identifier_array(vm['l2DomainIDs'])
    assert_identifier_array(vm['zoneIDs'])
    assert_identifier_array(vm['subnetIDs'])

    expect(vm['interfaces']).to be_a_kind_of(Array)
    assert_interface(vm['interfaces'].first)

    assert_resync_info(vm['resyncInfo'])
  end

  def assert_policy_groups(policy_groups)
    expect(policy_groups.count).to be > 0
    policy_group = policy_groups.first
    assert_policy_group(policy_group)
  end

  def assert_policy_group(policy_group)
    assert_time_fields(policy_group, %w(lastUpdatedDate creationDate))
    assert_identifier_fields(policy_group, %w(ID lastUpdatedBy owner parentID))
    assert_string_fields(policy_group, %w(parentType name type))
    assert_integer_fields(policy_group, %w(policyGroupID))
    assert_boolean_property_fields(policy_group, %w(external))
    assert_entity_scope(policy_group['entityScope'])
  end

  def assert_interface(interface)
    assert_time_fields(interface, %w(lastUpdatedDate creationDate))
    assert_identifier_fields(interface, %w(ID lastUpdatedBy owner parentID VMUUID domainID attachedNetworkID zoneID VPortID))
    assert_string_fields(interface, %w(parentType name domainName zoneName attachedNetworkType networkName VPortName))
    assert_ip_fields(interface, %w(netmask gateway IPAddress))
    assert_mac_address_property_fields(interface, %w(MAC))
    assert_entity_scope(interface['entityScope'])
  end

  def assert_resync_info(resync_info)
    assert_time_fields(resync_info, %w(lastUpdatedDate creationDate lastRequestTimestamp))
    assert_identifier_fields(resync_info, %w(ID lastUpdatedBy owner parentID))
    assert_string_fields(resync_info, %w(parentType status))
    assert_integer_fields(resync_info, %w(lastTimeResyncInitiated))
    assert_entity_scope(resync_info['entityScope'])
  end

  def assert_string_fields(obj, string_fields)
    expect(obj).to include(*string_fields)

    string_fields.each do |string_field|
      string = obj[string_field]
      expect(string).to be_an(String)
      expect(string.length).to be > 0
    end
  end

  def assert_integer_fields(obj, integer_fields)
    expect(obj).to include(*integer_fields)

    integer_fields.each do |integer_field|
      integer = obj[integer_field]
      expect(integer).to be_an(Integer)
    end
  end

  def assert_identifier_fields(obj, identifier_fields)
    expect(obj).to include(*identifier_fields)

    identifier_fields.each do |identifier_field|
      identifier = obj[identifier_field]
      expect(identifier =~ UUID_REGEXP).to be 0
    end
  end

  def assert_route_property_fields(obj, route_property_fields)
    expect(obj).to include(*route_property_fields)

    route_property_fields.each do |route_property_field|
      route_property = obj[route_property_field]
      expect(route_property =~ ROUTE_PROPERTY_REGEXP).to be 0
    end
  end

  def assert_ip_fields(obj, ip_fields)
    expect(obj).to include(*ip_fields)

    ip_fields.each do |ip_field|
      ip_address = obj[ip_field]
      expect(ip_address =~ IP_ADDR_REGEXP).to be 0
    end
  end

  def assert_mac_address_property_fields(obj, mac_address_property_fields)
    expect(obj).to include(*mac_address_property_fields)

    mac_address_property_fields.each do |mac_address_property_field|
      mac_address = obj[mac_address_property_field]
      expect(mac_address =~ MAC_ADDR_REGEXP).to be 0
    end
  end

  def assert_boolean_property_fields(obj, boolean_property_fields)
    expect(obj).to include(*boolean_property_fields)

    boolean_property_fields.each do |boolean_property_field|
      boolean_property = obj[boolean_property_field]
      expect(boolean_property).to be(!!boolean_property)
    end
  end

  def assert_identifier_array(identifier_array)
    expect(identifier_array).to be_a_kind_of(Array)

    identifier_array.each do |identifier|
      expect(identifier =~ UUID_REGEXP).to be 0
    end
  end

  def assert_time_fields(obj, time_fields)
    expect(obj).to include(*time_fields)

    time_fields.each do |time_field|
      timestamp = obj[time_field]
      expect(timestamp).to be_an(Integer)
      time = nil
      expect do
        time = Time.at(timestamp / 1000).utc
      end.to_not raise_error

      expect(time).to be < Time.now.utc
    end
  end

  def assert_enabled_disabled_inherited_fields(obj, enabled_disabled_inherited_fields)
    expect(obj).to include(*enabled_disabled_inherited_fields)

    enabled_disabled_inherited_fields.each do |enabled_disabled_inherited_field|
      enabled_disabled_inherited = obj[enabled_disabled_inherited_field]
      expect(enabled_disabled_inherited).to be_in(%w(ENABLED DISABLED INHERITED))
    end
  end

  def assert_entity_scope(entity_scope)
    expect(entity_scope).to be_in(%w(ENTERPRISE GLOBAL))
  end

  def assert_ip_type(ip_type)
    expect(ip_type).to be_in(%w(IPV4 IPV6 DUALSTACK))
  end
end
