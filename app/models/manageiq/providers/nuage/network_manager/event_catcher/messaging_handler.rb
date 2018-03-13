class ManageIQ::Providers::Nuage::NetworkManager::EventCatcher::MessagingHandler < Qpid::Proton::MessagingHandler
  def initialize(options = {})
    require 'qpid_proton'

    super()
    @options = options

    @topics                = @options.delete(:topics)
    @test_connection       = @options.delete(:test_connection)
    @message_handler_block = @options.delete(:message_handler_block)
    @url                   = @options.delete(:url)
    @timeout               = @options.delete(:amqp_connect_timeout) || 5.seconds
  end

  def on_container_start(container)
    $nuage_log.debug("#{self.class.log_prefix} Starting AMQP")
    Timeout.timeout(@timeout) { @conn = container.connect(@url, @options) }
    unless @test_connection
      @topics.each { |topic| @conn.open_receiver("topic://#{topic}") }
    end
  rescue Timeout::Error
    raise MiqException::MiqHostError, "Timeout connecting to AMQP endpoint #{@url}"
  end

  def on_connection_open(connection)
    # In case connection test was requested, close the connection immediately.
    connection.container.stop if @test_connection
  end

  def on_connection_error(connection)
    msg = "#{self.class.log_prefix} AMQP on_connection_error: #{connection.condition}"
    $nuage_log.debug(msg)
    raise MiqException::MiqHostError, msg
  end

  def on_transport_error(transport)
    msg = "#{self.class.log_prefix} AMQP on_transport_error: #{transport.connection.condition}"
    $nuage_log.debug(msg)
    raise MiqException::MiqHostError, msg
  end

  def on_message(_delivery, message)
    @message_handler_block&.call(JSON.parse(message.body))
  end

  def on_transport_close(transport)
    msg = "#{self.class.log_prefix} AMQP on_transport_close: #{transport.connection.condition}"
    $nuage_log.debug(msg)
    raise MiqException::MiqHostError, msg
  end

  def stop
    unless @conn.nil? || @conn.container.stopped
      $nuage_log.debug("#{self.class.log_prefix} Stopping AMQP")
      @conn.container.stop
    end
    @conn = nil
  end

  def self.log_prefix
    "MIQ(#{name})"
  end
end
