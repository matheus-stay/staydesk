require 'rails_helper'

# O ouvinte de SLA herda o processamento das regras, mas não pode responder aos
# eventos do produto: inscrito ao lado do ouvinte original, ele fazia cada
# automação rodar duas vezes e o cliente recebia dois avisos do mesmo ticket.
RSpec.describe Staydesk::SlaAutomationListener do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }

  it 'answers only the SLA events' do
    ouvinte = described_class.instance

    expect(ouvinte).to respond_to(:staydesk_sla_warning, :staydesk_sla_breached, :staydesk_sla_met)
    expect(ouvinte).not_to respond_to(:conversation_created)
    expect(ouvinte).not_to respond_to(:conversation_updated)
    expect(ouvinte).not_to respond_to(:message_created)
  end

  it 'runs an automation once when the conversation is created' do
    AutomationRule.create!(account: account, name: 'Aviso', event_name: 'conversation_created',
                           conditions: [{ 'attribute_key' => 'status', 'filter_operator' => 'equal_to', 'values' => ['open'] }],
                           actions: [{ 'action_name' => 'add_private_note', 'action_params' => ['recebido'] }])
    conversation = create(:conversation, account: account, inbox: inbox, status: :open)
    dispatcher = AsyncDispatcher.new
    dispatcher.load_listeners

    dispatcher.publish_event('conversation.created', Time.zone.now, { conversation: conversation })

    expect(conversation.messages.where(private: true, content: 'recebido').count).to eq(1)
  end
end
