# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)


## Unreleased as of Sprint 91 ending 2018-07-30

### Added
- Implement CREATE operation for CloudSubnet [(#117)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/117)
- Check for invalid api_version string [(#116)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/116)
- Destroy dependent entities when parent is deleted [(#115)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/115)
- Infer related CloudSubnet in case of NetworkPort refresh [(#114)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/114)
- Relate FloatingIp to NetworkRouter [(#113)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/113)
- Reduce memoization in targeted refresh [(#112)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/112)
- Targeted refresh for NetworkPorts [(#111)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/111)
- Targeted refresh for FloatingIp [(#110)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/110)
- Targeted refresh for L2 and L3 CloudSubnets [(#109)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/109)
- Targeted refresh for CloudNetwork::Floating [(#108)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/108)
- Narrow down focus of targeted refresh [(#107)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/107)
- Properly subclass CloudSubnet [(#105)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/105)
- Support DELETE operations powered by AnsibleRunner [(#104)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/104)

## Unreleased as of Sprint 90 ending 2018-07-16

### Added
- Temporarily remove many-to-many from NetworkRouter [(#102)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/102)
- Inventory vPort entities (Nuage) into NetworkPort model (MIQ) [(#101)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/101)

## Unreleased as of Sprint 87 ending 2018-06-04

### Added
- Inventory L3 Domain (Nuage) into NetworkRouter (MIQ) [(#93)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/93)

## Gaprindashvili-3 - Released 2018-05-15

### Added
- Add `stop_event_monitor_queue_on_change` method [(#65)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/65)
- Redirect logs into log/nuage.log file [(#66)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/66)
- Don't run EventCatcher when user opts-in for "None" [(#69)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/69)
- Also connect to CNAAlarms AMQP topic [(#73)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/73)
- Don't raise exceptions from within AMQP callbacks [(#78)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/78)

### Fixed
- Add name method [(#62)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/62)
- Handle subnets with missing gateway/netmask [(#68)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/68)

## Unreleased as of Sprint 85 ending 2018-05-07

### Added
- Prefix Nuage events with "nuage" [(#84)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/84)
- Harden refresh parser [(#71)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/71)

## Gaprindashvili-1 - Released 2018-01-31

### Added
- Implement graph inventory refresh for network manager [(#13)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/13)
- Provide extensive unit tests for legacy refresher [(#12)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/12)
- Install qpid_proton for Travis [(#11)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/11)
- Assign :ems_ref to the event [(#59)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/59)
- Upgrade qpid_proton related stuff to support v0.19.0 [(#58)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/58)

### Fixed
- Fix exception handing for credential validation on raw_connect [(#40)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/40)
- Fix a problem when no policy groups exist [(#4)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/4)
- Fix protocol selection when adding a new nuage provider [(#45)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/45)
- Human readable error when selecting wrong security protocol [(#43)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/43)
- Return empy list instead of nil for responses with empty bodies [(#53)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/53)

## Unreleased as of Sprint 72 ending 2017-10-30

### Added
- Enable Nuage network manager [(#33)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/33)
- Update raw_connect to simplify validation from UI [(#32)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/32)
- Use AMQP fallback endpoints when available [(#30)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/30)
- Connect events to targeted refresh [(#28)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/28)
- Implement targeted refresh for NetworkManager [(#20)](https://github.com/ManageIQ/manageiq-providers-nuage/pull/20)
