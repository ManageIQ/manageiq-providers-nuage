module ManageIQ::Providers::Nuage::ManagerMixin
  extend ActiveSupport::Concern

  module ClassMethods
    def params_for_create
      {
        :fields => [
          {
            :component    => "select",
            :id           => "api_version",
            :name         => "api_version",
            :label        => _("API Version"),
            :initialValue => 'v3',
            :isRequired   => true,
            :validate     => [{:type => "required"}],
            :options      => [
              {
                :label => _('Version 3.2'),
                :value => 'v3_2',
              },
              {
                :label => _('Version 4.0'),
                :value => 'v4_0',
              },
              {
                :label => _('Version 5.0'),
                :value => 'v5_0',
              },
            ],
          },
          {
            :component => 'sub-form',
            :id        => 'endpoints-subform',
            :name      => 'endpoints-subform',
            :title     => _('Endpoints'),
            :fields    => [
              :component => 'tabs',
              :name      => 'tabs',
              :fields    => [
                {
                  :component => 'tab-item',
                  :id        => 'default-tab',
                  :name      => 'default-tab',
                  :title     => _('Default'),
                  :fields    => [
                    {
                      :component              => 'validate-provider-credentials',
                      :id                     => 'authentications.default.valid',
                      :name                   => 'authentications.default.valid',
                      :skipSubmit             => true,
                      :isRequired             => true,
                      :validationDependencies => %w[type api_version],
                      :fields                 => [
                        {
                          :component    => "select",
                          :id           => "endpoints.default.security_protocol",
                          :name         => "endpoints.default.security_protocol",
                          :label        => _("Security Protocol"),
                          :isRequired   => true,
                          :initialValue => 'ssl-with-validation',
                          :validate     => [{:type => "required"}],
                          :options      => [
                            {
                              :label => _("SSL without validation"),
                              :value => "ssl-no-validation"
                            },
                            {
                              :label => _("SSL"),
                              :value => "ssl-with-validation"
                            },
                            {
                              :label => _("Non-SSL"),
                              :value => "non-ssl"
                            }
                          ]
                        },
                        {
                          :component  => "text-field",
                          :id         => "endpoints.default.hostname",
                          :name       => "endpoints.default.hostname",
                          :label      => _("Hostname (or IPv4 or IPv6 address)"),
                          :isRequired => true,
                          :validate   => [{:type => "required"}],
                        },
                        {
                          :component  => "text-field",
                          :id         => "endpoints.default.port",
                          :name       => "endpoints.default.port",
                          :label      => _("API Port"),
                          :type       => "number",
                          :isRequired => true,
                          :validate   => [{:type => "required"}],
                        },
                        {
                          :component  => "text-field",
                          :id         => "authentications.default.userid",
                          :name       => "authentications.default.userid",
                          :label      => _("Username"),
                          :isRequired => true,
                          :validate   => [{:type => "required"}],
                        },
                        {
                          :component  => "password-field",
                          :id         => "authentications.default.password",
                          :name       => "authentications.default.password",
                          :label      => _("Password"),
                          :type       => "password",
                          :isRequired => true,
                          :validate   => [{:type => "required"}],
                        },
                      ]
                    },
                  ]
                },
                {
                  :component => 'tab-item',
                  :id        => 'events-tab',
                  :name      => 'events-tab',
                  :title     => _('Events'),
                  :fields    => [
                    {
                      :component    => 'protocol-selector',
                      :id           => 'event_stream_selection',
                      :name         => 'event_stream_selection',
                      :skipSubmit   => true,
                      :initialValue => 'none',
                      :label        => _('Type'),
                      :options      => [
                        {
                          :label => _('None'),
                          :value => 'none',
                        },
                        {
                          :label => _('AMQP'),
                          :value => _('amqp'),
                          :pivot => 'endpoints.amqp.hostname',
                        },
                      ],
                    },
                    {
                      :component              => 'validate-provider-credentials',
                      :id                     => 'endpoints.amqp.valid',
                      :name                   => 'endpoints.amqp.valid',
                      :skipSubmit             => true,
                      :validationDependencies => %w[type event_stream_selection],
                      :condition              => {
                        :when => 'event_stream_selection',
                        :is   => 'amqp',
                      },
                      :fields                 => [
                        {
                          :component  => "text-field",
                          :id         => "endpoints.amqp.hostname",
                          :name       => "endpoints.amqp.hostname",
                          :label      => _("Hostname (or IPv4 or IPv6 address)"),
                          :helperText => _("Used to authenticate with Nuage AMQP Messaging Bus for event handling."),
                          :isRequired => true,
                          :validate   => [{:type => "required"}],
                        },
                        {
                          :component   => "text-field",
                          :id          => "endpoints.amqp_fallback1.hostname",
                          :name        => "endpoints.amqp_fallback1.hostname",
                          :placeholder => _("Hostname (or IPv4 or IPv6 address)"),
                          :label       => _("Fallback Hostname 1"),
                        },
                        {
                          :component   => "text-field",
                          :id          => "endpoints.amqp_fallback2.hostname",
                          :name        => "endpoints.amqp_fallback2.hostname",
                          :placeholder => _("Hostname (or IPv4 or IPv6 address)"),
                          :label       => _("Fallback Hostname 2"),
                        },
                        {
                          :component    => "text-field",
                          :id           => "endpoints.amqp.port",
                          :name         => "endpoints.amqp.port",
                          :label        => _("API Port"),
                          :type         => "number",
                          :isRequired   => true,
                          :initialValue => 5672,
                          :validate     => [{:type => "required"}],
                        },
                        {
                          :component  => "text-field",
                          :id         => "authentications.amqp.userid",
                          :name       => "authentications.amqp.userid",
                          :label      => _("Username"),
                          :isRequired => true,
                          :validate   => [{:type => "required"}],
                        },
                        {
                          :component  => "password-field",
                          :id         => "authentications.amqp.password",
                          :name       => "authentications.amqp.password",
                          :label      => _("Password"),
                          :type       => "password",
                          :isRequired => true,
                          :validate   => [{:type => "required"}],
                        },
                      ],
                    },
                  ],
                },
              ],
            ],
          },
        ]
      }.freeze
    end

    # Verify Credentials
    #
    # args: {
    #   "api_version" => String,
    #   "endpoints" => {
    #     "default" => {
    #       "hostname" => String,
    #       "port" => Integer,
    #       "security_protocol" => String,
    #     },
    #     "amqp" => {
    #       "hostname" => String,
    #       "port" => String,
    #     },
    #     "amqp_fallback1" => {
    #       "hostname" => String,
    #     },
    #     "amqp_fallback2" => {
    #       "hostname" => String,
    #     },
    #   },
    #   "authentications" => {
    #     "default" =>
    #       "userid" => String,
    #       "password" => String,
    #     }
    #     "amqp" => {
    #       "userid" => String,
    #       "password" => String,
    #     }
    #   }
    # }
    def verify_credentials(args)
      endpoint_name = args.dig("endpoints").keys.first
      endpoint = args.dig("endpoints", endpoint_name)
      authentication = args.dig("authentications", endpoint_name)

      userid, password = authentication&.values_at('userid', 'password')
      password = ManageIQ::Password.try_decrypt(password)
      password ||= find(args["id"]).authentication_password(endpoint_name) if args["id"]

      hostname, port, security_protocol = endpoint&.values_at('hostname', 'port', 'security_protocol')

      if endpoint_name == 'default'
        endpoint_opts = {
          :protocol => security_protocol,
          :hostname => hostname,
          :api_port => port
        }

        !!raw_connect(userid, password, endpoint_opts)
      else
        amqp_hosts = [hostname] + (1..2).map { |i| args.dig("endpoints", "amqp_fallback#{i}", "hostname") }.compact

        ManageIQ::Providers::Nuage::NetworkManager::EventCatcher::Stream.test_amqp_connection(
          :urls                      => amqp_hosts.map { |host| [host, port].join(':') },
          :sasl_allow_insecure_mechs => true, # Only plain (insecure) mechanism currently supported
          :user                      => userid,
          :password                  => password
        )
      end
    end

    def raw_connect(username, password, endpoint_opts)
      protocol    = endpoint_opts[:protocol].strip if endpoint_opts[:protocol]
      hostname    = endpoint_opts[:hostname].strip
      api_port    = endpoint_opts[:api_port]
      # In case API port is represented as a string, ensure it has no whitespaces.
      api_port.strip! if api_port.kind_of?(String)
      api_version = endpoint_opts[:api_version].to_s.strip

      # TODO(miha-plesko): Update UI to never pass in invalid version string like '? string:v2 ?'
      raise MiqException::MiqInvalidCredentialsError, 'Invalid API Version' unless api_version_valid?(api_version)

      url = auth_url(protocol, hostname, api_port, api_version)
      $nuage_log.debug("Connecting to Nuage VSD with url #{url}")

      connection_rescue_block do
        ManageIQ::Providers::Nuage::NetworkManager::VsdClient.new(url, username, password)
      end
    end

    def base_url(protocol, server, port)
      scheme = %w(ssl ssl-with-validation).include?(protocol) ? "https" : "http"
      URI::Generic.build(:scheme => scheme, :host => server, :port => port).to_s
    end

    def auth_url(protocol, server, port, version)
      URI(base_url(protocol, server, port)).tap { |url| url.path = "/nuage/api/#{version}" }.to_s
    end

    def translate_exception(err)
      require 'excon'
      case err
      when Excon::Errors::Unauthorized
        MiqException::MiqInvalidCredentialsError.new("Login failed due to a bad username or password.")
      when Excon::Errors::Timeout
        MiqException::MiqUnreachableError.new("Login attempt timed out")
      when Excon::Errors::SocketError
        MiqException::MiqHostError.new("Socket error: #{err.message}")
      when MiqException::MiqInvalidCredentialsError, MiqException::MiqHostError
        err
      when Net::HTTPBadResponse
        MiqException::MiqEVMLoginError.new("Login failed due to a bad security protocol, hostname or port.")
      else
        MiqException::MiqEVMLoginError.new("Unexpected response returned from system: #{err.message}")
      end
    end

    def connection_rescue_block
      yield
    rescue => err
      miq_exception = translate_exception(err)

      $nuage_log.error("Error Class=#{err.class.name}, Message=#{err.message}")
      raise miq_exception
    end

    def api_version_valid?(value)
      !!(value =~ /^v\d+[_.]\d+/) # e.g. 'v5_0' or 'v5.0'
    end
  end

  def connect(options = {})
    raise "no credentials defined" if self.missing_credentials?(options[:auth_type])

    username = options[:user] || authentication_userid(options[:auth_type])
    password = options[:pass] || authentication_password(options[:auth_type])
    protocol = options[:protocol] || security_protocol
    server   = options[:ip] || address
    port     = options[:port] || self.port
    version  = options[:version] || api_version

    endpoint_opts = {:protocol => protocol, :hostname => server, :api_port => port, :api_version => version}
    self.class.raw_connect(username, password, endpoint_opts)
  end

  def verify_credentials(auth_type = nil, options = {})
    auth_type ||= 'default'

    raise MiqException::MiqInvalidCredentialsError, "Unsupported auth type: #{auth_type}" unless supported_auth_types.include?(auth_type.to_s)
    raise MiqException::MiqHostError, "No credentials defined" if missing_credentials?(auth_type)

    options[:auth_type] = auth_type
    case auth_type.to_s
    when 'default' then verify_api_credentials(options)
    when 'amqp'    then verify_amqp_credentials(options)
    end
  end

  def event_monitor_options
    @event_monitor_options ||= begin
      amqp_auth = authentications.detect { |a| a.authtype == 'amqp' }
      {
        :ems                       => self,
        :urls                      => amqp_urls,
        :sasl_allow_insecure_mechs => true, # Only plain (insecure) mechanism currently supported
        :user                      => amqp_auth.userid,
        :password                  => amqp_auth.password
      }
    end
  end

  private

  def amqp_urls
    amqp_endpoints = endpoints.select { |e| e.role == 'amqp' || e.role.start_with?('amqp_fallback') }
    amqp_endpoints.map do |e|
      "#{e.hostname}:#{e.port}"
    end
  end

  def verify_api_credentials(options = {})
    self.class.connection_rescue_block do
      with_provider_connection(options) {}
      true
    end
  end

  def verify_amqp_credentials(_options = {})
    ManageIQ::Providers::Nuage::NetworkManager::EventCatcher::Stream.test_amqp_connection(event_monitor_options)
  end

  def stop_event_monitor_queue_on_change
    if event_monitor_class && !new_record? && (authentications.detect(&:changed?) || endpoints.detect(&:changed?))
      $nuage_log.info("EMS: [#{name}], Credentials or endpoints have changed, stopping Event Monitor. It will be restarted by the WorkerMonitor.")
      stop_event_monitor_queue
    end
  end

  def stop_event_monitor_queue_on_credential_change
    stop_event_monitor_queue_on_change
  end
end
