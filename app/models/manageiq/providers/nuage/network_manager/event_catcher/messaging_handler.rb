class ManageIQ::Providers::Nuage::NetworkManager::EventCatcher::MessagingHandler < Qpid::Proton::MessagingHandler
  attr_reader :errors

  def initialize(options = {})
    require 'qpid_proton'

    super()
    @options = options

    @topics                = @options.delete(:topics)
    @test_connection       = @options.delete(:test_connection)
    @message_handler_block = @options.delete(:message_handler_block)
    @url                   = @options.delete(:url)
    @timeout               = @options.delete(:amqp_connect_timeout) || 5.seconds
    @errors                = []
  end

  def on_container_start(container)
    Timeout.timeout(@timeout) { @conn = container.connect(@url, @options) }
    unless @test_connection
      @topics.each { |topic| @conn.open_receiver("topic://#{topic}") }
    end
  rescue Timeout::Error
    add_error(MiqException::MiqHostError.new("Timeout connecting to AMQP endpoint #{@url}"), container)
  rescue Errno::ECONNREFUSED => err
    add_error(MiqException::MiqHostError.new("ECONNREFUSED connecting to AMQP endpoint #{@url}: #{err}"), container)
  rescue SocketError => err
    add_error(MiqException::MiqHostError.new("Error connecting to AMQP endpoint #{@url}: #{err}"), container)
  end

  def on_connection_open(connection)
    # In case connection test was requested, close the connection immediately.
    connection.container.stop if @test_connection
  end

  def on_connection_error(connection)
    add_error("AMQP connection error: #{connection.condition}")
  end

  def on_message(_delivery, message)
    @message_handler_block&.call(JSON.parse(message.body))
  end

  def stop
    unless @conn.nil? || @conn.container.stopped
      $nuage_log.debug("#{self.class.log_prefix} Stopping AMQP")
      @conn.container.stop
    end
    @conn = nil
  end

  # Memorize error and request container stop if container is given.
  def add_error(err, container_to_stop = nil)
    err = MiqException::Error.new(err) if err.kind_of?(String)
    $nuage_log.debug("#{self.class.log_prefix} #{err.class.name}: #{err.message}")
    @errors << err
    container_to_stop.stop unless container_to_stop.nil? || container_to_stop.stopped
  end

  def raise_for_error
    raise @errors.first unless @errors.empty? # first error is root cause, others are just followup
  end

  def self.log_prefix
    "MIQ(#{name})"
  end
end
