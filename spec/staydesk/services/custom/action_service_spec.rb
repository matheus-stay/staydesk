require 'rails_helper'

RSpec.describe Custom::ActionService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: 'open') }
  let(:user) { create(:user, account: account, role: :administrator) }
  let!(:espera) { Staydesk::TicketStatus.create!(account: account, name: 'Em espera', base_status: 'pending') }

  def macro_with(actions)
    create(:macro, account: account, created_by: user, updated_by: user, actions: actions, visibility: :global)
  end

  it 'writes a conversation field from a macro, like a Zendesk trigger does' do
    macro = macro_with([{ 'action_name' => 'staydesk_set_attribute', 'action_params' => %w[servidor salmos] }])

    Macros::ExecutionService.new(macro, conversation, user).perform

    expect(conversation.reload.custom_attributes['servidor']).to eq('salmos')
  end

  it 'clears the field when the value comes empty' do
    conversation.update!(custom_attributes: { 'servidor' => 'salmos' })
    macro = macro_with([{ 'action_name' => 'staydesk_set_attribute', 'action_params' => ['servidor', ''] }])

    Macros::ExecutionService.new(macro, conversation, user).perform

    expect(conversation.reload.custom_attributes).not_to have_key('servidor')
  end

  it 'applies a ticket status, aligning the base status' do
    macro = macro_with([{ 'action_name' => 'staydesk_set_ticket_status', 'action_params' => [espera.id] }])

    Macros::ExecutionService.new(macro, conversation, user).perform

    conversation.reload
    expect(conversation.custom_attributes['staydesk_status']).to eq('Em espera')
    expect(conversation.status).to eq('pending')
  end

  it 'runs the same actions from an automation rule' do
    rule = create(:automation_rule, account: account, event_name: 'conversation_created',
                                    conditions: [{ attribute_key: 'status', filter_operator: 'equal_to', values: ['open'], query_operator: nil }],
                                    actions: [{ action_name: 'staydesk_set_ticket_status', action_params: [espera.id] },
                                              { action_name: 'staydesk_set_attribute', action_params: %w[tipo_de_demanda incidentes] }])

    AutomationRules::ActionService.new(rule, account, conversation).perform

    conversation.reload
    expect(conversation.status).to eq('pending')
    expect(conversation.custom_attributes['tipo_de_demanda']).to eq('incidentes')
  end

  it 'accepts the StayDesk actions in the macro validation' do
    macro = build(:macro, account: account, created_by: user, updated_by: user, visibility: :global,
                          actions: [{ 'action_name' => 'staydesk_set_attribute', 'action_params' => %w[servidor tito] }])

    expect(macro).to be_valid
  end
end
