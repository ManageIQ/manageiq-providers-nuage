if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

require 'qpid_proton'

# Uncomment in case you use vcr cassettes
VCR.configure do |config|
  config.ignore_hosts 'codeclimate.com' if ENV['CI']
  config.cassette_library_dir = File.join(ManageIQ::Providers::Nuage::Engine.root, 'spec/vcr_cassettes')
  config.default_cassette_options = {
    :decode_compressed_response => true
  }
end

Dir[Rails.root.join("spec/shared/**/*.rb")].each { |f| require f }
Dir[ManageIQ::Providers::Nuage::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }

# Utility function to test Ansible::runner bad status handling
def raises_upon_errored_playbook
  expect(Ansible::Runner).to receive(:run).and_return(response_bad)
  expect { yield }.to raise_error(MiqException::Error)
end
