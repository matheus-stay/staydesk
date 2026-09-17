require 'rails_helper'

RSpec.describe Staydesk::TicketStatus do
  let(:account) { create(:account) }

  it 'keeps the list attribute definition in sync with the active statuses' do
    described_class.create!(account: account, name: 'Novo', base_status: 'open', position: 0)
    described_class.create!(account: account, name: 'Fechado', base_status: 'resolved', position: 1)
    inactive = described_class.create!(account: account, name: 'Antigo', base_status: 'resolved', position: 2, active: false)

    definition = account.custom_attribute_definitions.find_by(attribute_key: 'staydesk_status')
    expect(definition.attribute_display_type).to eq('list')
    expect(definition.attribute_model).to eq('conversation_attribute')
    expect(definition.attribute_values).to eq(%w[Novo Fechado])

    inactive.update!(active: true)
    expect(definition.reload.attribute_values).to eq(%w[Novo Fechado Antigo])
  end

  it 'rejects a base status outside the four of the conversation' do
    status = described_class.new(account: account, name: 'X', base_status: 'closed')
    expect(status).not_to be_valid
  end

  it 'prefers the default status of a base, then the first active one' do
    first = described_class.create!(account: account, name: 'Resolvido', base_status: 'resolved', position: 0)
    default = described_class.create!(account: account, name: 'Fechado', base_status: 'resolved', position: 1, default_for_base: true)

    expect(described_class.default_for(account, 'resolved')).to eq(default)
    default.update!(default_for_base: false)
    expect(described_class.default_for(account, 'resolved')).to eq(first)
    expect(described_class.default_for(account, 'pending')).to be_nil
  end
end
