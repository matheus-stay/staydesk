require 'rails_helper'

# Contagem de tickets pelos campos do ticket, pela API dos indicadores.
RSpec.describe Staydesk::KpiService do
  let(:account) { create(:account) }
  let(:email) { create(:inbox, account: account, enable_auto_assignment: false, channel: create(:channel_email, account: account)) }

  before do
    create(:custom_attribute_definition, account: account, attribute_model: 'conversation_attribute', attribute_key: 'tipo_de_demanda',
                                         attribute_display_name: 'Tipo de Demanda', attribute_display_type: 'list',
                                         attribute_values: %w[bugs dúvidas])
    create(:custom_attribute_definition, account: account, attribute_model: 'conversation_attribute', attribute_key: 'whmcs_ticket_id',
                                         attribute_display_name: 'WHMCS Ticket ID', attribute_display_type: 'text')
    [{ 'tipo_de_demanda' => 'bugs' }, { 'tipo_de_demanda' => 'bugs' }, { 'tipo_de_demanda' => 'dúvidas' }, {}].each do |campos|
      create(:conversation, account: account, inbox: email, custom_attributes: campos)
    end
    create(:conversation, account: account, inbox: email, custom_attributes: { 'tipo_de_demanda' => 'bugs' }, created_at: 30.days.ago)
  end

  it 'counts the tickets created in the period by each list field value' do
    por_campo = described_class.new(account: account, since: 7.days.ago, ate: Time.current).perform[:por_campo]

    expect(por_campo.keys).to eq(['tipo_de_demanda'])
    expect(por_campo['tipo_de_demanda']).to eq(nome: 'Tipo de Demanda', total: 4, valores: { 'bugs' => 2, 'dúvidas' => 1, 'sem_valor' => 1 })
  end
end
