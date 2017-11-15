module ManageIQ::Providers::Nuage::ManagerMixin
  extend ActiveSupport::Concern

  module ClassMethods
    def raw_connect(username, password, endpoint_opts)
      protocol    = endpoint_opts[:protocol].strip if endpoint_opts[:protocol]
      hostname    = endpoint_opts[:hostname].strip
      api_port    = endpoint_opts[:api_port]
      # In case API port is represented as a string, ensure it has no whitespaces.
      api_port.strip! if api_port.kind_of?(String)
      # v5_0 is the default API version unless it is given in the opts.
      api_version = endpoint_opts[:api_version] ? endpoint_opts[:api_version].strip : 'v5_0'

      url = auth_url(protocol, hostname, api_port, api_version)
      _log.info("Connecting to Nuage VSD with url #{url}")

      connection_rescue_block do
        ManageIQ::Providers::Nuage::NetworkManager::VsdClient.new(url, username, password)
      end
    end

    def auth_url(protocol, server, port, version)
      scheme = protocol == "ssl-with-validation" ? "https" : "http"
      URI::Generic.build(:scheme => scheme, :host => server, :port => port, :path => "/nuage/api/#{version}").to_s
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

      _log.error("Error Class=#{err.class.name}, Message=#{err.message}")
      raise miq_exception
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

    raise MiqException::MiqInvalidCredentialsError, "Unsupported auth type: #{auth_type}" unless supports_authentication?(auth_type)
    raise MiqException::MiqHostError, "No credentials defined" if missing_credentials?(auth_type)

    options[:auth_type] = auth_type
    case auth_type.to_s
    when 'default' then verify_api_credentials(options)
    when 'amqp'    then verify_amqp_credentials(options)
    end
  end

  def event_monitor_options
    @event_monitor_options ||= begin
      {
        :ems                       => self,
        :urls                      => amqp_urls,
        :sasl_allow_insecure_mechs => true, # Only plain (insecure) mechanism currently supported
      }
    end
  end

  private

  def amqp_urls
    amqp_endpoints = endpoints.select { |e| e.role == 'amqp' || e.role.start_with?('amqp_fallback') }
    amqp_auth      = authentications.detect { |a| a.authtype == 'amqp' }

    amqp_endpoints.map do |e|
      url = "#{e.hostname}:#{e.port}"
      url = "#{amqp_auth.userid}:#{amqp_auth.password}@#{url}" if amqp_auth
      url
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
end
