class ManageIQ::Providers::Nuage::NetworkManager::EventCatcher::Stream
  include Vmdb::Logging

  def self.test_amqp_connection(options = {})
    return false if options[:urls].blank?
    # Ensure we just test the connection. AMQP channel will be established and
    # started, however it will be immediately stopped.
    options[:test_connection] = true

    stream = new(options)
    ok = stream.with_fallback_urls(options[:urls]) do
      stream.connection.run
      return true
    end
    raise MiqException::MiqHostError, "Could not connect to any of the #{options[:urls].count} AMQP hostnames" unless ok
    true
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
    with_fallback_urls(@options[:urls]) do
      connection.run
    end
  end

  def stop
    @handler&.stop
  end

  def connection
    unless @connection
      @handler = ManageIQ::Providers::Nuage::NetworkManager::EventCatcher::MessagingHandler.new(@options.clone)
      @connection = Qpid::Proton::Container.new(@handler)
    end
    @connection
  end

  def with_fallback_urls(urls)
    urls.each_with_index do |url, idx|
      endpoint_str = "ActiveMQ endpoint #{idx + 1}/#{@options[:urls].count} (#{url})"
      _log.info("#{self.class.log_prefix} Connecting to #{endpoint_str}")
      begin
        @options[:url] = url
        yield
      rescue MiqException::MiqHostError, Errno::ECONNREFUSED, SocketError => err
        _log.info("#{self.class.log_prefix} #{endpoint_str} errored: #{err}")
        stop
        reset_connection
      end
    end
    false
  end

  def reset_connection
    @connection = nil
  end
end
