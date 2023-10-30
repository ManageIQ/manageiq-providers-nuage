# Note, we're using string class name to avoid autoloading the class since it requires
# qpid_proton installed.
describe "ManageIQ::Providers::Nuage::NetworkManager::EventCatcher::MessagingHandler", :qpid_proton => true do
  before do
    subject.instance_variable_set(:@conn, conn)
  end

  let(:options)   { {} }
  let(:container) { double('container', :stopped => false, :stop => nil) }
  let(:conn)      { double('connection', :open_receiver => nil, :container => container) }

  subject { ManageIQ::Providers::Nuage::NetworkManager::EventCatcher::MessagingHandler.new(options) }

  it 'default connection timeout' do
    expect(subject.instance_variable_get(:@timeout)).to eq(5.seconds)
  end

  describe '.on_container_start' do
    context 'timeout occurs' do
      before do
        allow(container).to receive(:connect) { sleep 2 }
      end

      let(:options) { { :amqp_connect_timeout => 0.01, :topics => ['topic'], :url => 'demo.url' } }

      it 'timeout occurs' do
        expect { subject.on_container_start(container) }.not_to raise_error
        expect { subject.raise_for_error }.to raise_error(MiqException::MiqHostError, 'Timeout connecting to AMQP endpoint demo.url')
      end
    end

    context 'connection error occurs' do
      let(:options) { { :url => 'demo.url' } }

      it 'ECONNREFUSED' do
        allow(container).to receive(:connect) { raise Errno::ECONNREFUSED }
        expect { subject.on_container_start(container) }.not_to raise_error
        expect { subject.raise_for_error }.to raise_error(MiqException::MiqHostError, 'ECONNREFUSED connecting to AMQP endpoint demo.url: Connection refused')
      end

      it 'SocketError' do
        allow(container).to receive(:connect) { raise SocketError }
        expect { subject.on_container_start(container) }.not_to raise_error
        expect { subject.raise_for_error }.to raise_error(MiqException::MiqHostError, 'Error connecting to AMQP endpoint demo.url: SocketError')
      end
    end
  end

  it '.on_connection_error' do
    allow(conn).to receive(:condition).and_return('ERR')
    expect { subject.on_connection_error(conn) }.not_to raise_error
    expect { subject.raise_for_error }.to raise_error(MiqException::Error, 'AMQP connection error: ERR')
  end

  describe '.on_connection_open' do
    let(:options) { { :test_connection => true } }

    it 'when testing connection' do
      expect(container).to receive(:stop)
      subject.on_connection_open(conn)
    end
  end

  it '.stop' do
    expect(container).to receive(:stop)
    subject.stop
  end
end
