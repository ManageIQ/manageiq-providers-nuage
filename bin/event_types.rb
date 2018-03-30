# Produce all possible event type strings and print them to console. This makes sense since
# there are many event types and they are built with this pattern: `{entity}_{type}`. Nuage
# has many different entities hence many different event types.
#
# Usage: ruby bin/event_types.rb > event_types.txt

ENTITIES = %w(
  addressmap
  addressrange
  aggregatemetadata
  application
  applicationbinding
  applicationperformancemanagement
  applicationperformancemanagementbinding
  autodiscoveredcluster
  autodiscovereddatacenter
  autodiscoveredgateway
  autodiscoveredhypervisor
  avatar
  bfdsession
  bgpneighbor
  bgppeer
  bgpprofile
  bootstrap
  bootstrapactivation
  brconnection
  bridgeinterface
  bulkstatistics
  captiveportalprofile
  certificate
  cms
  command
  component
  connectionendpoint
  container
  containerinterface
  containerresync
  cosremarkingpolicy
  cosremarkingpolicytable
  csnatpool
  ctranslationmap
  customproperty
  defaultgateway
  demarcationservice
  destinationurl
  dhcpoption
  diskstat
  domain
  domaintemplate
  dscpforwardingclassmapping
  dscpforwardingclasstable
  dscpremarkingpolicy
  dscpremarkingpolicytable
  ducgroup
  ducgroupbinding
  eamconfig
  egressaclentrytemplate
  egressacltemplate
  egressadvfwdentrytemplate
  egressadvfwdtemplate
  egressdomainfloatingipaclentrytemplate
  egressdomainfloatingipacltemplate
  egressfloatingipaclentrytemplate
  egressfloatingipacltemplate
  egressqospolicy
  enterprise
  enterprisenetwork
  enterprisepermission
  enterpriseprofile
  enterprisesecureddata
  enterprisesecurity
  eventlog
  firewallacl
  firewallrule
  floatingip
  gateway
  gatewaysecureddata
  gatewaysecurity
  gatewaytemplate
  globalmetadata
  group
  groupkeyencryptionprofile
  hostinterface
  hsc
  ikecertificate
  ikeencryptionprofile
  ikegateway
  ikegatewayconfig
  ikegatewayconnection
  ikegatewayprofile
  ikepsk
  ikesubnet
  infraconfig
  infrastructureaccessprofile
  infrastructuregatewayprofile
  infrastructurevscprofile
  ingressaclentrytemplate
  ingressacltemplate
  ingressadvfwdentrytemplate
  ingressadvfwdtemplate
  ingressexternalserviceentrytemplate
  ingressexternalservicetemplate
  ingressqospolicy
  ipreservation
  job
  keyservermember
  keyservermonitor
  keyservermonitorencryptedseed
  keyservermonitorseed
  keyservermonitorsek
  l2domain
  l2domaintemplate
  l4service
  l4servicegroup
  l7applicationsignature
  ldapconfiguration
  license
  licensestatus
  link
  location
  lteinformation
  ltestatistics
  me
  metadata
  mirrordestination
  monitoringport
  monitorscope
  multicastchannelmap
  multicastlist
  multicastrange
  multinicvport
  natmapentry
  networklayout
  networkmacrogroup
  networkperformancebinding
  networkperformancemeasurement
  nexthop
  nsgateway
  nsgatewaytemplate
  nsggroup
  nsginfo
  nsgpatchprofile
  nsgredundancygroup
  nsgroutingpolicybinding
  nsgupgradeprofile
  nsport
  nsporttemplate
  nsredundantport
  ospfarea
  ospfinstance
  ospfinterface
  overlayaddresspool
  overlaymirrordestination
  overlaymirrordestinationtemplate
  overlaypatnatentry
  patipentry
  patmapper
  patnatpool
  performancemonitor
  permission
  pgexpression
  pgexpressiontemplate
  policydecision
  policyentry
  policygroup
  policygrouptemplate
  policyobjectgroup
  policystatement
  port
  portmapping
  porttemplate
  proxyarpfilter
  psnatpool
  pspatmap
  ptranslationmap
  publicnetwork
  qos
  qospolicer
  ratelimiter
  redirectiontarget
  redirectiontargettemplate
  redundancygroup
  resync
  routingpolicy
  service
  sharednetworkresource
  site
  spatsourcespool
  sshkey
  ssidconnection
  staticroute
  statistics
  statisticscollector
  statisticspolicy
  subnet
  subnettemplate
  systemconfig
  tca
  tier
  trunk
  underlay
  uplinkconnection
  uplinkroutedistinguisher
  user
  usercontext
  vcenter
  vcentercluster
  vcenterdatacenter
  vcenterhypervisor
  virtualfirewallpolicy
  virtualfirewallrule
  virtualip
  vlan
  vlantemplate
  vm
  vminterface
  vnf
  vnfcatalog
  vnfdescriptor
  vnfdomainmapping
  vnfinterface
  vnfinterfacedescriptor
  vnfmetadata
  vnfthresholdpolicy
  vpnconnection
  vport
  vportmirror
  vrs
  vrsaddressrange
  vrsconfig
  vrsmetrics
  vrsredeploymentpolicy
  vsc
  vsd
  vsgredundantport
  vsp
  wirelessport
  zfbautoassignment
  zfbrequest
  zone
  zonetemplate
).freeze

EVENT_TYPES = %w(
  create
  update
  delete
).freeze

def print_event_types_per_type
  types    = EVENT_TYPES.uniq.sort
  entities = ENTITIES.uniq.sort

  puts "Printing event types for #{entities.count} entites and #{types.count} event types"

  types.each do |event_type|
    puts "\n------------------------------"
    puts "EVENT TYPE: #{event_type}"
    puts "------------------------------\n"
    entities.each do |entity|
      puts combine(entity, event_type)
    end
  end
end

def print_alarm_event_types
  types = EVENT_TYPES.uniq.sort

  puts "Printing ALARM event types for #{types.count} event types"

  types.each do |event_type|
    puts combine('alarm', event_type)
  end
end

def combine(entity, event_type)
  "- nuage_#{entity}_#{event_type}"
end

#
# Main
#
if $PROGRAM_NAME == __FILE__
  print_event_types_per_type
  puts "\n"
  print_alarm_event_types
end
