describe 'travis.yml' do
  let(:travis) { YAML.safe_load(File.open(ManageIQ::Providers::Nuage::Engine.root.join('.travis.yml'))) }
  let(:versions) { travis['rvm'] }

  it "matches versions and excludes for multiple ruby versions" do
    if versions.length > 1
      excludes = travis.dig('matrix', 'exclude').map { |ex| ex['rvm'] }.sort.uniq
      expect(excludes.length).to eq(versions.length - 1)
      expect(versions).to include(excludes.first)
    end
  end

  it "does not exclude any testsuite for single ruby version" do
    if versions.length == 1
      excludes = travis.dig('matrix', 'exclude')
      expect(excludes).to be(nil)
    end
  end
end
