describe ManageIQ::Providers::Nuage::ToolbarOverrides::NetworkRouterCenter do
  let(:button_group)  { described_class.definition["#{described_class.name}.nuage_network_router"] }
  let(:group_items)   { button_group.buttons }
  let(:dropdown_edit) { group_items.first }

  it 'assert button group' do
    expect(button_group).not_to be_nil
    expect(group_items.size).to eq(1)
  end

  it 'assert Edit drop-down' do
    expect(dropdown_edit[:title]).to eq(N_('Edit'))
    expect(dropdown_edit[:items].size).to eq(1)
    expect(dropdown_edit[:items][0][:title]).to eq(N_('Create L3 Cloud Subnet'))
  end
end
