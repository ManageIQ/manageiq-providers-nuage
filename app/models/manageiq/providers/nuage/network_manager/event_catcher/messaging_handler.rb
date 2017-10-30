class ManageIQ::Providers::Nuage::NetworkManager::EventCatcher::MessagingHandler < Qpid::Proton::Handler::MessagingHandler
  def initialize(options = {})
    require 'qpid_proton'

    super()
    @options = options

    @topics = @options.delete(:topics)
    @test_connection = @options.delete(:test_connection)
    @message_handler_block = @options.delete(:message_handler_block)
  end

  def on_start(event)
    @conn = event.container.connect(@options)
    unless @test_connection
      @topics.each { |topic| event.container.create_receiver(@conn, :source => "topic://#{topic}") }
    end
  end

  def on_connection_opened(event)
    # In case connection test was requested, close the connection immediately.
    event.container.stop if @test_connection
  end

  def on_connection_error(_event)
    raise MiqException::MiqInvalidCredentialsError, "Connection failed due to bad username or password"
  end

  def on_transport_error(_event)
    # Only raise error if single URL is used, as otherwise qpid will attempt
    # to fallback to alternative URLs.
    raise MiqException::MiqHostError, "Transport error" unless @options[:urls].length > 1
  end

  def on_message(event)
    @message_handler_block.call(JSON.parse(event.message.body)) if @message_handler_block
  end

  def stop
    @conn.close
  end
end
