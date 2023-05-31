if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

Dir[Rails.root.join("spec/shared/**/*.rb")].each { |f| require f }
Dir[File.join(__dir__, "support/**/*.rb")].each { |f| require f }

require "manageiq/providers/nuage"
require "qpid_proton"

VCR.configure do |config|
  config.ignore_hosts 'codeclimate.com' if ENV['CI']
  config.cassette_library_dir = File.join(ManageIQ::Providers::Nuage::Engine.root, 'spec/vcr_cassettes')

  config.default_cassette_options = {
    :decode_compressed_response => true
  }

  config.define_cassette_placeholder(Rails.application.secrets.nuage_defaults[:host]) do
    Rails.application.secrets.nuage[:host]
  end
  config.define_cassette_placeholder('NUAGE_NETWORK_AUTHORIZATION') do
    Base64.encode64("#{Rails.application.secrets.nuage[:userid]}:#{Rails.application.secrets.nuage[:password]}".chomp)
  end
end
