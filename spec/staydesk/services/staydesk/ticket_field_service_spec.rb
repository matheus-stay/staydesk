require 'rails_helper'

RSpec.describe Staydesk::TicketFieldService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: 'open') }

  def campo(chave, obrigatorio: false, tipo: :text)
    create(:custom_attribute_definition, account: account, attribute_key: chave,
                                         attribute_display_name: chave.titleize,
                                         attribute_display_type: tipo,
                                         attribute_model: :conversation_attribute,
                                         staydesk_required_to_resolve: obrigatorio)
  end

  it 'lists what is missing to resolve, ignoring blanks' do
    campo('tipo_de_demanda', obrigatorio: true)
    campo('servidor', obrigatorio: true)
    campo('observacao')
    conversation.update!(custom_attributes: { 'tipo_de_demanda' => 'Suporte', 'servidor' => '  ' })

    faltando = described_class.new(account).faltando(conversation).map(&:attribute_key)

    expect(faltando).to eq(['servidor'])
  end

  it 'reads every field with its value for whoever asks by API' do
    campo('tipo_de_demanda', obrigatorio: true)
    conversation.update!(custom_attributes: { 'tipo_de_demanda' => 'Suporte' })

    linha = described_class.new(account).para_conversa(conversation).first

    expect(linha).to include(key: 'tipo_de_demanda', value: 'Suporte', required_to_resolve: true, filled: true)
  end

  it 'takes false as a filled checkbox' do
    campo('cobrado', obrigatorio: true, tipo: :checkbox)
    conversation.update!(custom_attributes: { 'cobrado' => false })

    expect(described_class.new(account).faltando(conversation)).to be_empty
  end

  describe 'resolving' do
    before { campo('tipo_de_demanda', obrigatorio: true) }

    it 'stops the agent while a required field is empty' do
      Current.user = agent

      conversation.status = :resolved

      expect(conversation).not_to be_valid
      expect(conversation.errors.full_messages.join).to include('Tipo De Demanda')
    ensure
      Current.user = nil
    end

    it 'lets the agent through once it is filled' do
      Current.user = agent
      conversation.update!(custom_attributes: { 'tipo_de_demanda' => 'Suporte' })

      expect(conversation.reload.update(status: :resolved)).to be(true)
    ensure
      Current.user = nil
    end

    it 'does not stop automation, bot or automatic resolution' do
      Current.user = nil

      expect(conversation.update(status: :resolved)).to be(true)
    end

    it 'does not touch any other status change' do
      Current.user = agent

      expect(conversation.update(status: :pending)).to be(true)
    ensure
      Current.user = nil
    end
  end
end
