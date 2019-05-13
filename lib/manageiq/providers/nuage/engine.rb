module ManageIQ
  module Providers
    module Nuage
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::Providers::Nuage

        def self.vmdb_plugin?
          true
        end

        def self.plugin_name
          _('Nuage Provider')
        end
      end
    end
  end
end
