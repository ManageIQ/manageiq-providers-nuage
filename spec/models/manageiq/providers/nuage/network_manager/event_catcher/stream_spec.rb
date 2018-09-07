describe ManageIQ::Providers::Nuage::NetworkManager::EventCatcher::Stream do
  before do
    allow(subject).to receive(:connection).and_return(conn)
  end

  let(:fallback_urls) { ['first.url'] }
  let(:messages)      { ['MSG'] }
  let(:conn) do
    double('conn', :handler => handler).tap do |conn|
      allow(conn).to receive(:run) { handler.mock_messages }
    end
  end
  let(:handler) do
    double('handler', :raise_for_error => nil).tap do |handler|
      allow(handler).to receive(:on_message) { |msg| curr_option(:message_handler_block).call(msg) }
      allow(handler).to receive(:mock_messages) { messages.each { |msg| handler.on_message(msg) } }
    end
  end

  subject { described_class.new(:urls => fallback_urls) }

  describe '.start' do
    it 'event is received' do
      events = []
      subject.start { |evt| events << evt }
      expect(events).to eq(['MSG'])
    end

    context 'multiple fallback urls' do
      let(:fallback_urls) { %w(first.url second.url third.url) }

      it 'urls are looped' do
        res = []
        subject.start { res << "URL=#{curr_option(:url)}" }
        expect(res).to eq(%w(URL=first.url URL=second.url URL=third.url))
      end

      context 'handler errors' do
        before do
          allow(handler).to receive(:on_message) do |msg|
            curr_option(:message_handler_block).call(msg)
            raise MiqException::Error
          end
        end

        it 'urls are looped' do
          res = []
          subject.start { res << "URL=#{curr_option(:url)}" }
          expect(res).to eq(%w(URL=first.url URL=second.url URL=third.url))
        end
      end
    end
  end

  def curr_option(option)
    subject.instance_variable_get(:@options)[option]
  end
end
