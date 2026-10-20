require 'rails_helper'

# Fila que depende de condição (o assunto, no N3) só decide depois de a conversa
# ser gravada. Esse save dentro do after_create_commit fazia o Rails pular os
# after_create_commit do núcleo que ainda faltavam: a conversa ficava sem número
# (display_id) e o evento conversation_created não saía, então nenhum gatilho
# rodava no ticket (prioridade, confirmação de recebimento).
RSpec.describe Staydesk::QueueRouter do
  let(:account) { create(:account) }
  let(:n3) { create(:team, account: account, name: 'suporte n3') }
  let(:email) { create(:inbox, :with_email, account: account) }

  before do
    Staydesk::Queue.create!(account: account, name: 'Tickets N3', team: n3, position: 0,
                            conditions: [{ 'attribute_key' => 'mail_subject', 'filter_operator' => 'contains', 'values' => ['otimização'] }])
  end

  def criar
    create(:conversation, account: account, inbox: email, additional_attributes: { 'mail_subject' => 'Preciso de otimização' })
  end

  it 'routes to the conditional queue and still loads the display id' do
    conversa = criar

    expect(conversa.team).to eq(n3)
    expect(conversa.display_id).to be_present
  end

  it 'still dispatches conversation_created, which the triggers listen to' do
    eventos = []
    allow(Rails.configuration.dispatcher).to receive(:dispatch).and_wrap_original do |original, nome, *args, **opts|
      eventos << nome
      original.call(nome, *args, **opts)
    end

    criar

    expect(eventos).to include(Events::Types::CONVERSATION_CREATED)
  end
end
