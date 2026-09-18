require 'rails_helper'

RSpec.describe 'tempo online no KPI' do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:account_user) { account.account_users.find_by(user: agent) }
  let(:disponivel) { Staydesk::AgentStatus.create!(account: account, name: 'Disponível', availability: 'online', counts_as_online: true) }
  let(:reuniao) { Staydesk::AgentStatus.create!(account: account, name: 'Reunião', availability: 'busy', counts_as_online: false) }
  let(:plantao) { Staydesk::AgentStatus.create!(account: account, name: 'Plantão', availability: 'online', counts_as_online: false) }

  before { allow(OnlineStatusTracker).to receive(:get_available_users).and_return({}) }

  def periodo(status, desde, ate)
    Staydesk::AgentStatusPeriod.create!(account: account, account_user: account_user, agent_status: status,
                                        started_at: desde, ended_at: ate)
  end

  it 'counts only the statuses marked as online time, whatever their availability' do
    periodo(disponivel, 3.hours.ago, 2.hours.ago)
    periodo(reuniao, 2.hours.ago, 1.hour.ago)
    periodo(plantao, 1.hour.ago, 30.minutes.ago)

    linha = Staydesk::KpiService.new(account: account, since: 1.day.ago, ate: Time.current).perform[:agentes]
                                .find { |item| item[:user_id] == agent.id }

    expect(linha[:segundos_online]).to be_within(60).of(3600)
    expect(linha[:segundos_no_periodo]).to be_within(60).of(3600 * 2.5)
  end

  it 'averages per worked day and across the team' do
    periodo(disponivel, 2.days.ago, 2.days.ago + 4.hours)
    periodo(disponivel, 1.day.ago, 1.day.ago + 2.hours)

    resultado = Staydesk::KpiService.new(account: account, since: 3.days.ago, ate: Time.current).perform
    linha = resultado[:agentes].find { |item| item[:user_id] == agent.id }

    expect(linha[:dias_online]).to eq(2)
    expect(linha[:media_diaria_online_segundos]).to be_within(60).of(3.hours.to_i)
    expect(resultado[:resumo_dos_agentes]).to include(agentes_com_tempo_online: 1)
    expect(resultado[:resumo_dos_agentes][:tempo_online_medio_segundos]).to be_within(60).of(6.hours.to_i)
  end
end
