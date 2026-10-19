require 'rails_helper'

RSpec.describe Staydesk::DistributionTrace do
  let(:account) { create(:account) }
  let(:n1) { create(:team, account: account, name: 'Suporte N1') }
  let(:whatsapp) do
    create(:inbox, account: account, channel: create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false))
  end
  let(:ana) { create(:user, account: account, role: :agent) }

  before do
    create(:team_member, team: n1, user: ana)
    create(:inbox_member, inbox: whatsapp, user: ana)
    Staydesk::Queue.create!(account: account, name: 'Chat e WhatsApp', team: n1, position: 0,
                            accept_required: true, accept_timeout_seconds: 30)
  end

  def online(agentes)
    allow(OnlineStatusTracker).to receive(:get_available_users).and_return(agentes.to_h { |a| [a.id.to_s, 'online'] })
  end

  def na_fila
    online([])
    create(:conversation, account: account, inbox: whatsapp, team: n1, status: :open)
  end

  it 'walks the whole path and names who would get the conversation' do
    conversa = na_fila
    online([ana])

    trilha = described_class.new(conversa).perform

    expect(trilha[:para_em]).to be_nil
    expect(trilha[:etapas].last).to include(etapa: 'rodizio_tem_o_candidato', escolheria: ana.id.to_s)
  end

  it 'says where it stops when nobody is online' do
    conversa = na_fila

    expect(described_class.new(conversa).perform[:para_em]).to eq('alguem_na_roda_do_canal')
  end

  it 'flags a conversation held by a bot, which the distribution skips without a word' do
    conversa = na_fila
    conversa.update_columns(assignee_agent_bot_id: create(:agent_bot).id) # rubocop:disable Rails/SkipsModelValidations
    online([ana])

    expect(described_class.new(conversa).perform[:para_em]).to eq('sem_bot_responsavel')
  end
end
