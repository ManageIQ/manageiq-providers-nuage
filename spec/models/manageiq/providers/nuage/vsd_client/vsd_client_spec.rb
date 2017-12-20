describe ManageIQ::Providers::Nuage::NetworkManager::VsdClient do
  before(:each) do
    allow_any_instance_of(described_class).to receive(:initialize)
  end

  let(:rest_call) { double('Rest') }
  let(:client) do
    c = described_class.new
    c.instance_variable_set(:@rest_call, rest_call)
    c
  end

  describe "get_list edge cases" do
    let(:response_404)      { double('Response', :code => 404) }
    let(:response_empty)    { double('Response', :code => 200, :body => '') }
    let(:response_simplest) { double('Response', :code => 200, :body => '[]') }

    it "response code not 200 should return nil" do
      response(response_404)
      expect(client.send(:get_list, 'some-url')).to be_nil
    end

    it "response body empty should return empty list" do
      response(response_empty)
      expect(client.send(:get_list, 'some-url')).to eq([])
    end

    it "response body empty list should return empty list" do
      response(response_simplest)
      expect(client.send(:get_list, 'some-url')).to eq([])
    end
  end

  describe "get_first edge cases" do
    let(:element) { double('list element') }

    it "nil is handled" do
      allow(client).to receive(:get_list).and_return(nil)
      expect(client.send(:get_first, 'some-url')).to be_nil
    end

    it "empty list is handled" do
      allow(client).to receive(:get_list).and_return([])
      expect(client.send(:get_first, 'some-url')).to be_nil
    end

    it "normal list is handled" do
      allow(client).to receive(:get_list).and_return([element])
      expect(client.send(:get_first, 'some-url')).to eq(element)
    end
  end

  def response(response)
    allow(client.instance_variable_get(:@rest_call)).to receive(:get).and_return(response)
  end
end
