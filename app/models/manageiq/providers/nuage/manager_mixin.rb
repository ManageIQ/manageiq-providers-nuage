module ManageIQ::Providers::Nuage::ManagerMixin
  extend ActiveSupport::Concern

  module ClassMethods
    def raw_connect(auth_url, username, password)
      ManageIQ::Providers::Nuage::NetworkManager::VsdClient.new(auth_url, username, password)
    end

    def auth_url(protocol, server, port, version)
      scheme = protocol == "ssl-with-validation" ? "https" : "http"
      "#{scheme}://#{server}:#{port}/nuage/api/#{version}"
    end
  end

  def connect(options = {})
    raise "no credentials defined" if self.missing_credentials?(options[:auth_type])

    protocol = options[:protocol] || security_protocol
    server   = options[:ip] || address
    port     = options[:port] || self.port
    username = options[:user] || authentication_userid(options[:auth_type])
    password = options[:pass] || authentication_password(options[:auth_type])
    version  = options[:version] || api_version

    url = auth_url(protocol, server, port, version)
    _log.info("Connecting to Nuage VSD with url #{url}")
    self.class.raw_connect(url, username, password)
  end

  def translate_exception(err)
    require 'excon'
    case err
    when Excon::Errors::Unauthorized
      MiqException::MiqInvalidCredentialsError.new "Login failed due to a bad username or password."
    when Excon::Errors::Timeout
      MiqException::MiqUnreachableError.new "Login attempt timed out"
    when Excon::Errors::SocketError
      MiqException::MiqHostError.new "Socket error: #{err.message}"
    when MiqException::MiqInvalidCredentialsError, MiqException::MiqHostError
      err
    else
      MiqException::MiqEVMLoginError.new "Unexpected response returned from system: #{err.message}"
    end
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
      url = ''
      amqp = connection_configuration_by_role('amqp')
      if (endpoint = amqp.try(:endpoint))
        url = "#{endpoint.hostname}:#{endpoint.port}"
      end

      if (authentication = amqp.try(:authentication))
        url = "#{authentication.userid}:#{authentication.password}@#{url}"
      end

      {
        :ems                       => self,
        :url                       => url,
        :sasl_allow_insecure_mechs => true, # Only plain (insecure) mechanism currently supported
      }
    end
  end

  private

  def verify_api_credentials(options = {})
    with_provider_connection(options) {}
    true
  rescue => err
    miq_exception = translate_exception(err)
    raise unless miq_exception

    _log.error("Error Class=#{err.class.name}, Message=#{err.message}")
    raise miq_exception
  end

  def verify_amqp_credentials(_options = {})
    ManageIQ::Providers::Nuage::NetworkManager::EventCatcher::Stream.test_amqp_connection(event_monitor_options)
  end

  def auth_url(protocol, server, port, version)
    self.class.auth_url(protocol, server, port, version)
  end
end
