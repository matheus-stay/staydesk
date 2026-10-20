require 'rails_helper'

# A camada realinha o status do ticket quando o status base muda, e isso grava a
# conversa de novo. Rodando antes dos after_update_commit do núcleo, esse save
# zerava `saved_change_to_status?`: o núcleo deixava de avisar "conversa aberta"
# e "conversa resolvida" (SLA, gatilhos, webhooks e pesquisa de satisfação não
# ficavam sabendo), e o chat reaberto pelo cliente voltava como "Novo".
RSpec.describe Conversation do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:eventos) { [] }

  before do
    Staydesk::TicketStatus.create!(account: account, name: 'Novo', base_status: 'open', position: 0, default_for_base: true)
    Staydesk::TicketStatus.create!(account: account, name: 'Em andamento', base_status: 'open', position: 1, apply_on_assign: true)
    Staydesk::TicketStatus.create!(account: account, name: 'Resolvido', base_status: 'resolved', position: 2, default_for_base: true)
    create(:inbox_member, inbox: inbox, user: agent)
    allow(Rails.configuration.dispatcher).to receive(:dispatch).and_wrap_original do |original, nome, *args, **opts|
      eventos << nome
      original.call(nome, *args, **opts)
    end
  end

  def conversa
    @conversa ||= create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox,
                                        assignee: agent, status: :open)
  end

  it 'still announces the resolution when the ticket status is realigned' do
    conversa
    eventos.clear
    conversa.update!(status: :resolved)

    expect(eventos).to include(Events::Types::CONVERSATION_RESOLVED, Events::Types::CONVERSATION_STATUS_CHANGED)
    expect(conversa.reload.custom_attributes['staydesk_status']).to eq('Resolvido')
  end

  def cliente_escreve
    create(:message, account: account, inbox: conversa.inbox, conversation: conversa.reload, message_type: :incoming, sender: contact)
  end

  # Chat (canal de trabalho coringa, que por padrão reabre na fila): como no
  # Zendesk, volta para a fila sem o agente anterior.
  it 'puts a chat reopened by the contact back in the queue, without the previous agent' do
    conversa.update!(status: :resolved)
    eventos.clear
    cliente_escreve

    expect(eventos).to include(Events::Types::CONVERSATION_OPENED, Events::Types::CONVERSATION_STATUS_CHANGED)
    expect(conversa.reload).to have_attributes(status: 'open', assignee_id: nil)
    expect(conversa.custom_attributes['staydesk_status']).to eq('Novo')
  end

  it 'keeps the chat with the agent when the agent reopens it' do
    conversa.update!(status: :resolved)
    conversa.reload.update!(status: :open)

    expect(conversa.reload.assignee_id).to eq(agent.id)
    expect(conversa.custom_attributes['staydesk_status']).to eq('Em andamento')
  end

  context 'with a ticket' do
    let(:inbox) { create(:inbox, :with_email, account: account) }

    it 'keeps the ticket with the agent and marks it in progress when the contact writes back' do
      conversa.update!(status: :resolved)
      eventos.clear
      cliente_escreve

      expect(eventos).to include(Events::Types::CONVERSATION_OPENED)
      expect(conversa.reload).to have_attributes(status: 'open', assignee_id: agent.id)
      expect(conversa.custom_attributes['staydesk_status']).to eq('Em andamento')
    end
  end

  it 'lets a work channel keep the reopened chat with the agent when configured' do
    Staydesk::LoadQueue.create!(account: account, key: 'chat', name: 'Chat', catch_all: true, reopen_to_queue: false)
    conversa.update!(status: :resolved)
    cliente_escreve

    expect(conversa.reload.assignee_id).to eq(agent.id)
  end
end
