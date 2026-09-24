require 'rails_helper'

RSpec.describe Staydesk::KpiService do
  let(:account) { create(:account) }
  # Sem distribuição automática: o KPI mede o que fica esperando na fila, e com
  # ela ligada a conversa sairia da espera no mesmo instante em que entra.
  let(:chat) { create(:inbox, account: account, enable_auto_assignment: false, channel: create(:channel_widget, account: account)) }
  let(:email) { create(:inbox, account: account, enable_auto_assignment: false, channel: create(:channel_email, account: account)) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:account_user) { account.account_users.find_by(user: agent) }

  before do
    allow(OnlineStatusTracker).to receive(:get_available_users).and_return({ agent.id.to_s => 'online' })
  end

  def resultado
    described_class.new(account: account, since: 7.days.ago, ate: Time.current).perform
  end

  it 'splits the average times by load queue' do
    create(:reporting_event, account_id: account.id, inbox_id: chat.id, name: 'first_response', value: 60,
                             value_in_business_hours: 60)
    create(:reporting_event, account_id: account.id, inbox_id: chat.id, name: 'first_response', value: 120,
                             value_in_business_hours: 120)
    create(:reporting_event, account_id: account.id, inbox_id: email.id, name: 'first_response', value: 600,
                             value_in_business_hours: 600)

    tempos = resultado[:tempos]

    expect(tempos['chat'][:primeira_resposta]).to include(segundos: 90, amostras: 2)
    expect(tempos['ticket'][:primeira_resposta]).to include(segundos: 600, amostras: 1)
  end

  it 'counts satisfaction the way the operation reads it' do
    conversation = create(:conversation, account: account, inbox: chat)
    [5, 4, 3, 1].each do |nota|
      create(:csat_survey_response, account: account, conversation: conversation, rating: nota,
                                    assigned_agent: agent)
    end

    csat = resultado[:csat]

    expect(csat[:respostas]).to eq(4)
    expect(csat[:satisfeitos]).to eq(2)
    expect(csat[:percentual]).to eq(50.0)
    expect(csat[:por_agente].first).to include(user_id: agent.id, satisfeitos: 2)
  end

  it 'reports what is waiting and for how long' do
    create(:conversation, account: account, inbox: chat, assignee: nil, status: 'open',
                          created_at: 30.minutes.ago)

    fila = resultado[:fila]

    expect(fila[:total]).to eq(1)
    expect(fila[:por_fila]['chat']).to eq(1)
    expect(fila[:espera_mais_antiga_em_segundos]).to be_within(60).of(1800)
  end

  it 'measures the time of each agent in each status and who is connected now' do
    disponivel = Staydesk::AgentStatus.create!(account: account, name: 'Disponível', availability: 'online')
    Staydesk::AgentStatusPeriod.create!(account: account, account_user: account_user, agent_status: disponivel,
                                        started_at: 2.hours.ago, ended_at: 1.hour.ago)

    linha = resultado[:agentes].find { |item| item[:user_id] == agent.id }

    expect(linha[:segundos_disponivel]).to be_within(60).of(3600)
    expect(linha[:online]).to be(true)
  end

  it 'only counts the slice of a status period that falls inside the window' do
    disponivel = Staydesk::AgentStatus.create!(account: account, name: 'Disponível', availability: 'online')
    Staydesk::AgentStatusPeriod.create!(account: account, account_user: account_user, agent_status: disponivel,
                                        started_at: 30.days.ago, ended_at: 6.days.ago)

    linha = resultado[:agentes].find { |item| item[:user_id] == agent.id }

    expect(linha[:segundos_disponivel]).to be_within(120).of(1.day.to_i)
  end
end
