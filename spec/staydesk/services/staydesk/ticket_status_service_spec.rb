require 'rails_helper'

RSpec.describe Staydesk::TicketStatusService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account, status: 'open') }
  let!(:novo) { Staydesk::TicketStatus.create!(account: account, name: 'Novo', base_status: 'open', position: 0, default_for_base: true) }
  let!(:espera) { Staydesk::TicketStatus.create!(account: account, name: 'Em espera', base_status: 'pending', position: 1) }
  let!(:fechado) { Staydesk::TicketStatus.create!(account: account, name: 'Fechado', base_status: 'resolved', position: 2, default_for_base: true) }

  it 'writes the attribute and aligns the base status in one go' do
    described_class.new(conversation).apply(espera)

    conversation.reload
    expect(conversation.status).to eq('pending')
    expect(conversation.custom_attributes['staydesk_status']).to eq('Em espera')
    expect(described_class.new(conversation).current).to eq(espera)
  end

  it 'moves to the default of the base when the base changes another way' do
    described_class.new(conversation).apply(espera)

    conversation.reload.resolved!

    expect(conversation.reload.custom_attributes['staydesk_status']).to eq('Fechado')
  end

  it 'keeps a custom status whose base still matches' do
    described_class.new(conversation).apply(espera)
    conversation.reload.update!(priority: 'high')

    expect(conversation.reload.custom_attributes['staydesk_status']).to eq('Em espera')
  end

  it 'drops the attribute when the new base has no status in the catalog' do
    described_class.new(conversation).apply(fechado)
    conversation.reload.snoozed!

    expect(conversation.reload.custom_attributes).not_to have_key('staydesk_status')
  end

  it 'clears snoozed_until when leaving snoozed' do
    conversation.update!(status: 'snoozed', snoozed_until: 1.day.from_now)
    described_class.new(conversation).apply(novo)

    expect(conversation.reload.snoozed_until).to be_nil
    expect(conversation.status).to eq('open')
  end

  context 'when a status is marked to apply on assignment' do
    let!(:em_andamento) do
      Staydesk::TicketStatus.create!(account: account, name: 'Em andamento', base_status: 'open', position: 3,
                                     apply_on_assign: true)
    end
    let(:agent) { create(:user, account: account, role: :agent) }

    it 'moves the conversation to it when someone takes the case' do
      described_class.new(conversation).apply(novo)

      conversation.reload.update!(assignee: agent)

      expect(conversation.reload.custom_attributes['staydesk_status']).to eq('Em andamento')
      expect(conversation.status).to eq('open')
    end

    it 'goes back to the default when the conversation returns to the queue' do
      conversation.update!(assignee: agent)
      expect(conversation.reload.custom_attributes['staydesk_status']).to eq('Em andamento')

      conversation.update!(assignee: nil)

      expect(conversation.reload.custom_attributes['staydesk_status']).to eq('Novo')
    end

    it 'leaves a waiting case alone when it gets an assignee' do
      described_class.new(conversation).apply(espera)

      conversation.reload.update!(assignee: agent)

      expect(conversation.reload.custom_attributes['staydesk_status']).to eq('Em espera')
    end
  end
end
