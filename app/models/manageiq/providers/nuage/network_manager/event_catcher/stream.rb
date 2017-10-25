class ManageIQ::Providers::Nuage::NetworkManager::EventCatcher::Stream
  include Vmdb::Logging

  def self.test_amqp_connection(options = {})
    # Ensure we just test the connection. AMQP channel will be established and
    # started, however it will be immediately stopped.
    options[:test_connection] = true
    begin
      stream = new(options)
      stream.connection.run
      true
    rescue => e
      _log.info("#{log_prefix} Failed connecting to ActiveMQ: #{e.message}")
      raise
    end
  end

  def self.log_prefix
    "MIQ(#{self.class.name})"
  end

  def initialize(options = {})
    require 'qpid_proton'

    @options = options
  end

  def start(&message_handler_block)
    _log.debug("#{self.class.log_prefix} Opening amqp connection using options #{@options}")
    @options[:message_handler_block] = message_handler_block if message_handler_block
    connection.run
  end

  def stop
    @handler.stop
  end

  def connection
    unless @connection
      @handler = ManageIQ::Providers::Nuage::NetworkManager::EventCatcher::MessagingHandler.new(@options)
      @connection = Qpid::Proton::Reactor::Container.new(@handler)
    end
    @connection
  end
end
