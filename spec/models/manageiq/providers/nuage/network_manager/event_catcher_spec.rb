describe ManageIQ::Providers::Nuage::NetworkManager::EventCatcher do
  it '.ems_class' do
    expect(described_class.ems_class).to eq(ManageIQ::Providers::Nuage::NetworkManager)
  end

  it 'settings_name' do
    expect(described_class.settings_name).to eq(:event_catcher_nuage_network)
  end

  describe 'stream' do
    describe 'start_batch' do
      before(:each) do
        allow(stream).to receive(:connection).and_return(connection)
        allow(stream).to receive(:sleep_poll_normal)
        @batches = []
      end

      let!(:stream)     { described_class::Stream.new }
      let!(:connection) { double }
      let(:burst1)      { %w(event1 event2) }
      let(:burst2)      { %w(event3 event4) }

      it 'burst should give single batch' do
        mock_event_bursts([burst1]) do
          stream.start_batch { |batch| collect_batches(batch) }
        end
        assert_thread_stopped
        expect(@batches).to eq([burst1])
      end

      it 'two consequent bursts should give two batches' do
        mock_event_bursts([burst1, burst2]) do
          print "got burst\n"
          stream.start_batch { |batch| collect_batches(batch) }
        end
        assert_thread_stopped
        expect(@batches).to eq([burst1, burst2])
      end
    end
  end

  def mock_event_bursts(bursts)
    bursts.each do |burst|
      allow(connection).to receive(:run) do
        burst.each do |event|
          stream.instance_variable_get(:@options)[:message_handler_block].call(event)
        end
      end
      yield
    end
  end

  def collect_batches(batch)
    @batches << batch
  end

  def assert_thread_stopped
    expect(stream.instance_variable_get(:@thread).alive?).to eq(false)
  end
end
