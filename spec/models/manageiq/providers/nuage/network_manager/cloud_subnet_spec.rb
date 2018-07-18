describe ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet do
  let(:ems)     { FactoryGirl.create(:ems_nuage_network_with_authentication, :api_version => 'v5.0') }
  let(:user)    { 123 }
  let(:job)     { MiqQueue.find_by(:method_name => 'delete_cloud_subnet') }
  let(:fixture) { :cloud_subnet_nuage }

  subject do
    FactoryGirl.create(
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

    it '.delete_cloud_subnet' do
      expect(Ansible::Runner).to receive(:run) do |env, vars, playbook|
        expect(env).to be_empty
        expect(vars.keys).to eq(%i(nuage_auth id kind))
        expect(vars[:id]).to eq(subject.ems_ref)
        expect(vars[:kind]).to eq('L3')
        expect(playbook.to_s).to end_with("/remove-subnet.yml")
        expect(File).to exist(playbook.to_s)
      end
      subject.delete_cloud_subnet
    end
  end

  context 'L2 subnet' do
    let(:fixture) { :cloud_subnet_l2_nuage }

    it '.kind' do
      expect(subject.kind).to eq('L2')
    end

    it '.delete_cloud_subnet' do
      expect(Ansible::Runner).to receive(:run) do |env, vars, playbook|
        expect(env).to be_empty
        expect(vars.keys).to eq(%i(nuage_auth id kind))
        expect(vars[:id]).to eq(subject.ems_ref)
        expect(vars[:kind]).to eq('L2')
        expect(playbook.to_s).to end_with("/remove-subnet.yml")
        expect(File).to exist(playbook.to_s)
      end
      subject.delete_cloud_subnet
    end
  end
end
