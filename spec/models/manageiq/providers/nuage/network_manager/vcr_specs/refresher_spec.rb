describe ManageIQ::Providers::Nuage::NetworkManager::Refresher do
  before(:each) do
    @ems = FactoryGirl.create(:ems_nuage_with_vcr_authentication, :port => 8443, :api_version => "v5_0", :security_protocol => "ssl-with-validation")
  end

  before(:each) do
    settings                          = OpenStruct.new
    settings.inventory_object_refresh = false

    allow(Settings.ems_refresh).to receive(:nuage_network).and_return(settings)

    userid   = Rails.application.secrets.nuage_network.try(:[], 'userid') || 'NUAGE_USER_ID'
    password = Rails.application.secrets.nuage_network.try(:[], 'password') || 'NUAGE_PASSWORD'

    # Ensure that VCR will obfuscate the basic auth
    VCR.configure do |c|
      # workaround for escaping host
      c.before_playback do |interaction|
        interaction.filter!(CGI.escape(@ems.hostname), @ems.hostname)
        interaction.filter!(CGI.escape('NUAGE_NETWORK_HOST'), 'nuagenetworkhost')
      end
      c.filter_sensitive_data('NUAGE_NETWORK_AUTHORIZATION') { Base64.encode64("#{userid}:#{password}").chomp }
    end
  end

  it ".ems_type" do
    expect(described_class.ems_type).to eq(:nuage_network)
  end

  it "will perform a full refresh" do
    2.times do # Run twice to verify that a second run with existing data does not change anything
      @ems.reload

      VCR.use_cassette(described_class.name.underscore) do
        EmsRefresh.refresh(@ems)

        @ems.reload
        assert_table_counts
      end
    end
  end

  def assert_table_counts
    expect(ExtManagementSystem.count).to eq(1)
    expect(NetworkGroup.count).to eq(2)
    expect(SecurityGroup.count).to eq(1)
  end
end
