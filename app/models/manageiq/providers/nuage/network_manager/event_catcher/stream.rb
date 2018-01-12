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
    @thread  = nil
    @batch   = Queue.new # thread-safe implementation of Array
  end

  def start_batch
    _log.debug("#{self.class.log_prefix} Opening amqp connection using options #{@options}")
    @options[:message_handler_block] = ->(event) { @batch << event }
    @thread = qpid_thread
    while @thread.alive? || !@batch.empty?
      sleep_poll_normal
      yield current_batch unless @batch.empty?
    end
  end

  def stop
    @thread.exit if @thread && @thread.alive?
  end

  def connection
    unless @connection
      @handler = ManageIQ::Providers::Nuage::NetworkManager::EventCatcher::MessagingHandler.new(@options)
      @connection = Qpid::Proton::Reactor::Container.new(@handler)
    end
    @connection
  end

  private

  def current_batch
    Array.new(@batch.size) { @batch.pop }
  end

  def sleep_poll_normal
    sleep(self.class.parent.worker_settings[:poll])
  end

  #
  # A simple thread `Thread.new { connection.run }` should normally be returned here.
  # But doing so we measure a huge performance drop: events are fetched from AMQP immediately,
  # but their processing is delayed for ~10min, which is horrible. It seems to be a problem
  # with qpid somehow eating resources of the main thread. A quick workaround for now is to
  # periodically pause qpid thread for a few seconds to let the main process access the resources.
  #
  def qpid_thread
    t_interval = self.class.parent.worker_settings[:qpid_rest_interval]
    t_sleep = self.class.parent.worker_settings[:qpid_rest_time]
    Thread.new do
      loop do
        begin
          Timeout.timeout(t_interval) { connection.run }
        rescue Timeout::Error
        rescue StandardError => e
          _log.error("Qpid thread error: #{e}")
          break
        end
        @handler.stop
        sleep(t_sleep)
      end
    end
  end
end
