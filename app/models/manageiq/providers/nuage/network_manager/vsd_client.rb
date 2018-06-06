require 'rest-client'
require 'rubygems'
require 'json'
module ManageIQ::Providers
  class Nuage::NetworkManager::VsdClient
    include Vmdb::Logging
    def initialize(server, user, password)
      @server = server
      @user = user
      @password = password
      @rest_call = Rest.new(server, user, password)
      connected, data = @rest_call.login
      if connected
        @enterprise_id = data
        return
      end
      $nuage_log.error('VSD Authentication failed')
    end

    def get_enterprises
      get_list('enterprises')
    end

    def get_enterprise(id)
      get_first("enterprises/#{id}")
    end

    def get_domains
      get_list('domains')
    end

    def get_domain(id)
      get_first("domains/#{id}")
    end

    def get_domains_for_enterprise(enterprise_id)
      get_list("enterprises/#{enterprise_id}/domains")
    end

    def get_zones
      exclude_name('BackHaulZone')
      get_list('zones')
    end

    def get_zone(id)
      exclude_name('BackHaulZone')
      get_first("zones/#{id}")
    end

    def get_subnets
      exclude_name('BackHaulSubnet')
      get_list('subnets')
    end

    def get_subnet(id)
      exclude_name('BackHaulSubnet')
      get_first("subnets/#{id}")
    end

    def get_subnets_for_domain(domain_id)
      exclude_name('BackHaulSubnet')
      get_list("domains/#{domain_id}/subnets")
    end

    def get_vms
      get_list('vms')
    end

    def get_policy_groups
      get_list('policygroups')
    end

    def get_policy_group(id)
      get_first("policygroups/#{id}")
    end

    def get_policy_groups_for_domain(domain_id)
      get_list("domains/#{domain_id}/policygroups")
    end

    def get_l2_domains
      get_list('l2domains')
    end

    private

    # TODO(miha-plesko): Is this filter really supposed to be used here in client? Looks like debugging leftover,
    # consider removing it.
    def exclude_name(name)
      @rest_call.append_headers("X-Nuage-FilterType", "predicate")
      @rest_call.append_headers("X-Nuage-Filter", "name ISNOT '#{name}'")
    end

    def get_list(url)
      response = @rest_call.get("#{@server}/#{url}")
      return unless response.code == 200
      return [] if response.body.empty?
      JSON.parse(response.body)
    end

    def get_first(url)
      list = get_list(url)
      return if list.nil? || list.empty?
      list.first
    end
  end
end
