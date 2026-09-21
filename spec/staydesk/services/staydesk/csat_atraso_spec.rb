require 'rails_helper'

# A pesquisa de satisfação não pode passar na frente da resposta que resolveu o
# chamado: no e-mail, as duas saem juntas e chegam fora de ordem.
RSpec.describe Staydesk::Csat do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }

  it 'waits five minutes by default' do
    expect(described_class.atraso(inbox)).to eq(5.minutes)
  end

  it 'honours the wait configured on the channel' do
    inbox.update!(csat_config: { described_class::CHAVE => 30 })

    expect(described_class.atraso(inbox)).to eq(30.minutes)
  end

  it 'accepts sending it right away' do
    inbox.update!(csat_config: { described_class::CHAVE => 0 })

    expect(described_class.atraso(inbox)).to eq(0.minutes)
  end

  it 'reads the wait from the configuration file' do
    Staydesk::ConfigImportService.new(
      account: account,
      config: { 'caixas' => [{ 'nome' => inbox.name, 'pesquisa_de_satisfacao' => true, 'pesquisa_apos_minutos' => 10 }] }
    ).perform

    expect(described_class.atraso(inbox.reload)).to eq(10.minutes)
  end

  it 'schedules the survey instead of sending it with the reply' do
    conversation = create(:conversation, account: account, inbox: inbox, status: :resolved)
    evento = Events::Base.new('conversation.resolved', Time.zone.now, conversation: conversation)

    expect(Staydesk::Csat::SurveyJob).to receive(:set).with(wait: 5.minutes).and_call_original
    CsatSurveyListener.instance.conversation_status_changed(evento)
  end

  it 'only sends the survey while the conversation is still resolved' do
    conversation = create(:conversation, account: account, inbox: inbox, status: :open)

    expect(CsatSurveyService).not_to receive(:new)
    Staydesk::Csat::SurveyJob.perform_now(conversation.id)
  end
end
