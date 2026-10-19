require 'rails_helper'

# O FCR conta as respostas por conversa. A ordem padrão das mensagens derrubava
# a consulta agrupada no Postgres assim que havia conversa resolvida no período.
RSpec.describe Staydesk::Kpi::VolumeService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }

  it 'counts first-contact resolution over conversations with replies' do
    de_primeira = create(:conversation, account: account, inbox: inbox)
    duas_vezes = create(:conversation, account: account, inbox: inbox)
    create(:message, account: account, inbox: inbox, conversation: de_primeira, message_type: :outgoing)
    2.times { create(:message, account: account, inbox: inbox, conversation: duas_vezes, message_type: :outgoing) }

    fcr = described_class.new(account: account, since: 1.day.ago, ate: Time.current).send(:calcular_fcr, [de_primeira.id, duas_vezes.id])

    expect(fcr).to eq(percentual: 50.0, base: 2)
  end
end
