describe ManageIQ::Providers::Nuage::NetworkManager::SecurityGroup do
  let(:ems)          { FactoryGirl.create(:ems_nuage_network_with_authentication, :api_version => 'v5.0') }
  let(:user)         { 123 }
  let(:job)          { MiqQueue.find_by(:method_name => 'delete_security_group') }
  let(:response_ok)  { double('ansible_response', :return_code => 0, :parsed_stdout => []) }
  let(:response_bad) { double('ansible_response', :return_code => 2, :parsed_stdout => []) }

  subject do
    FactoryGirl.create(
      :security_group_nuage,
      :ext_management_system => ems,
      :name                  => 'test',
      :ems_ref               => 'subnet_ref'
    )
  end

  it '.delete_security_group_queue' do
    subject.delete_security_group_queue(user)
    expect(job).to have_attributes(
      :class_name  => described_class.name,
      :method_name => 'delete_security_group',
      :instance_id => subject.id,
      :priority    => MiqQueue::NORMAL_PRIORITY,
      :role        => 'ems_operations',
      :zone        => ems.my_zone,
      :args        => []
    )
  end

  describe '.delete_security_group' do
    it 'happy path' do
      expect(Ansible::Runner).to receive(:run) do |env, vars, playbook|
        expect(env).to be_empty
        expect(vars.keys).to eq(%i(nuage_auth id))
        expect(vars[:id]).to eq(subject.ems_ref)
        expect(playbook.to_s).to end_with("/remove-policy-group.yml")
        expect(File).to exist(playbook.to_s)

        response_ok
      end
      subject.delete_security_group
    end

    it 'bad playbook status' do
      raises_upon_errored_playbook { subject.delete_security_group }
    end
  end
end
