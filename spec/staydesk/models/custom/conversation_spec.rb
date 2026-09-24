require 'rails_helper'

RSpec.describe Conversation do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :open) }

  it 'records one StayDesk event per tracked change' do
    Current.user = agent
    conversation.update!(status: :resolved, priority: :high)

    events = Staydesk::ConversationEvent.where(conversation: conversation).order(:id)
    expect(events.map(&:kind)).to contain_exactly('status_changed', 'priority_changed')
    expect(events.find_by(kind: 'status_changed')).to have_attributes(from_value: 'open', to_value: 'resolved', user_id: agent.id)
  ensure
    Current.reset
  end

  it 'records nothing when nothing tracked changed' do
    conversation.update!(custom_attributes: { 'x' => 1 })

    expect(Staydesk::ConversationEvent.where(conversation: conversation)).to be_empty
  end

  # Sem status desde a criação, o caso recém-chegado some das visões que filtram
  # por status do ticket e conta como "em atendimento" em quem olha só o base.
  describe 'ticket status on creation' do
    let!(:novo_status) do
      Staydesk::TicketStatus.create!(account: account, name: 'Novo', base_status: 'open', default_for_base: true)
    end

    it 'is born with the default status of its base status' do
      expect(conversation.custom_attributes[Staydesk::TicketStatus::ATTRIBUTE_KEY]).to eq('Novo')
    end

    it 'keeps a status that came explicitly, instead of overwriting it' do
      Staydesk::TicketStatus.create!(account: account, name: 'Em andamento', base_status: 'open', position: 1)
      outra = create(:conversation, account: account, inbox: inbox, status: :open,
                                    custom_attributes: { Staydesk::TicketStatus::ATTRIBUTE_KEY => 'Em andamento' })

      expect(outra.custom_attributes[Staydesk::TicketStatus::ATTRIBUTE_KEY]).to eq('Em andamento')
    end

    it 'stays silent when the account has no ticket statuses for that base' do
      novo_status.destroy!
      outra = create(:conversation, account: account, inbox: inbox, status: :open)

      expect(outra.custom_attributes[Staydesk::TicketStatus::ATTRIBUTE_KEY]).to be_nil
    end
  end
end
