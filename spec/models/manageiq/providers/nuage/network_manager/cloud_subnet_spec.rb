describe ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet do
  let(:ems)          { FactoryBot.create(:ems_nuage_network_with_authentication, :api_version => 'v5.0') }
  let(:user)         { 123 }
  let(:job)          { MiqQueue.find_by(:method_name => 'delete_cloud_subnet') }
  let(:fixture)      { :cloud_subnet_nuage }
  let(:response_ok)  { double('ansible_response', :return_code => 0, :parsed_stdout => []) }
  let(:response_bad) { double('ansible_response', :return_code => 2, :parsed_stdout => []) }

  subject do
    FactoryBot.create(
      fixture,
      :ext_management_system => ems,
      :name                  => 'test',
      :ems_ref               => 'subnet_ref'
    )
  end

  it '.delete_cloud_subnet_queue' do
    subject.delete_cloud_subnet_queue(user)
    expect(job).to have_attributes(
      :class_name  => described_class.name,
      :method_name => 'delete_cloud_subnet',
      :instance_id => subject.id,
      :priority    => MiqQueue::NORMAL_PRIORITY,
      :role        => 'ems_operations',
      :zone        => ems.my_zone,
      :args        => []
    )
  end

  context 'L3 subnet' do
    let(:fixture) { :cloud_subnet_l3_nuage }

    it '.kind' do
      expect(subject.kind).to eq('L3')
    end

    describe '.delete_cloud_subnet' do
      it 'happy path' do
        expect(Ansible::Runner).to receive(:run) do |env, vars, playbook|
          expect(env).to be_empty
          expect(vars.keys).to eq(%i(nuage_auth id kind))
          expect(vars[:id]).to eq(subject.ems_ref)
          expect(vars[:kind]).to eq('L3')
          expect(playbook.to_s).to end_with("/remove-subnet.yml")
          expect(File).to exist(playbook.to_s)

          response_ok
        end
        subject.delete_cloud_subnet
      end

      it 'bad playbook status' do
        raises_upon_errored_playbook { subject.delete_cloud_subnet }
      end
    end

    describe '.create_cloud_subnet' do
      let(:options) do
        {
          :name       => 'Subnet',
          :address    => '128.128.130.0',
          :netmask    => 'netmask',
          :gateway    => '128.128.130.1',
          :router_ref => 'router_ref'
        }
      end

      it 'happy path' do
        expect(Ansible::Runner).to receive(:run) do |env, vars, playbook|
          expect(env).to be_empty
          expect(vars.keys).to eq(%i(nuage_auth domain_id subnet_attributes))
          expect(vars[:domain_id]).to eq('router_ref')
          expect(vars[:subnet_attributes].keys).to eq(%i(name address netmask gateway))
          expect(playbook.to_s).to end_with("/create-subnet.yml")
          expect(File).to exist(playbook.to_s)

          response_ok
        end
        ems.create_cloud_subnet(options)
      end

      it 'bad playbook status' do
        raises_upon_errored_playbook { ems.create_cloud_subnet(options) }
      end
    end
  end

  context 'L2 subnet' do
    let(:fixture) { :cloud_subnet_l2_nuage }

    it '.kind' do
      expect(subject.kind).to eq('L2')
    end

    describe '.delete_cloud_subnet' do
      it 'happy path' do
        expect(Ansible::Runner).to receive(:run) do |env, vars, playbook|
          expect(env).to be_empty
          expect(vars.keys).to eq(%i(nuage_auth id kind))
          expect(vars[:id]).to eq(subject.ems_ref)
          expect(vars[:kind]).to eq('L2')
          expect(playbook.to_s).to end_with("/remove-subnet.yml")
          expect(File).to exist(playbook.to_s)

          response_ok
        end
        subject.delete_cloud_subnet
      end

      it 'bad playbook status' do
        raises_upon_errored_playbook { subject.delete_cloud_subnet }
      end
    end
  end
end
