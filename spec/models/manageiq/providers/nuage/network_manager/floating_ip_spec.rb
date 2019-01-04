describe ManageIQ::Providers::Nuage::NetworkManager::FloatingIp do
  let(:ems)          { FactoryBot.create(:ems_nuage_network_with_authentication, :api_version => 'v5.0') }
  let(:user)         { 123 }
  let(:job)          { MiqQueue.find_by(:method_name => 'delete_floating_ip') }
  let(:response_ok)  { double('ansible_response', :return_code => 0, :parsed_stdout => []) }
  let(:response_bad) { double('ansible_response', :return_code => 2, :parsed_stdout => []) }

  subject do
    FactoryBot.create(
      :floating_ip_nuage,
      :ext_management_system => ems,
      :name                  => 'test',
      :ems_ref               => 'floating_ip_ref'
    )
  end

  it '.delete_floating_ip_queue' do
    subject.delete_floating_ip_queue(user)
    expect(job).to have_attributes(
      :class_name  => described_class.name,
      :method_name => 'delete_floating_ip',
      :instance_id => subject.id,
      :priority    => MiqQueue::NORMAL_PRIORITY,
      :role        => 'ems_operations',
      :zone        => ems.my_zone,
      :args        => []
    )
  end

  describe '.delete_floating_ip' do
    it 'happy path' do
      expect(Ansible::Runner).to receive(:run) do |env, vars, playbook|
        expect(env).to be_empty
        expect(vars.keys).to eq(%i(nuage_auth id))
        expect(vars[:id]).to eq(subject.ems_ref)
        expect(playbook.to_s).to end_with("/remove-floating-ip.yml")
        expect(File).to exist(playbook.to_s)

        response_ok
      end
      subject.delete_floating_ip
    end

    it 'bad playbook status' do
      raises_upon_errored_playbook { subject.delete_floating_ip }
    end
  end
end
