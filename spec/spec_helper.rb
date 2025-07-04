if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

Dir[Rails.root.join("spec/shared/**/*.rb")].each { |f| require f }
Dir[File.join(__dir__, "support/**/*.rb")].each { |f| require f }

require "manageiq/providers/nuage"

RSpec.configure do |config|
  config.filter_run_excluding(:qpid_proton) unless ENV['CI'] || Gem.loaded_specs.key?('qpid_proton')
end

VCR.configure do |config|
  config.ignore_hosts 'codeclimate.com' if ENV['CI']
  config.cassette_library_dir = File.join(ManageIQ::Providers::Nuage::Engine.root, 'spec/vcr_cassettes')
  config.default_cassette_options = {
    :decode_compressed_response => true
  }

  config.define_cassette_placeholder('NUAGE_NETWORK_AUTHORIZATION') do
    Base64.encode64("#{VcrSecrets.nuage.userid}:#{VcrSecrets.nuage.password}".chomp)
  end

  VcrSecrets.define_all_cassette_placeholders(config, :nuage)
end
