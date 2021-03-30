module ManageIQ
  module Providers
    module Nuage
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::Providers::Nuage

        config.autoload_paths << root.join('lib').to_s

        initializer :append_secrets do |app|
          app.config.paths["config/secrets"] << root.join("config", "secrets.defaults.yml").to_s
          app.config.paths["config/secrets"] << root.join("config", "secrets.yml").to_s
        end

        def self.vmdb_plugin?
          true
        end

        def self.plugin_name
          _('Nuage Provider')
        end

        def self.init_loggers
          $nuage_log ||= Vmdb::Loggers.create_logger("nuage.log")
        end

        def self.apply_logger_config(config)
          Vmdb::Loggers.apply_config_value(config, $nuage_log, :level_nuage)
        end
      end
    end
  end
end
