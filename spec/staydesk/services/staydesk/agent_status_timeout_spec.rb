require 'rails_helper'

RSpec.describe 'tempo limite do status do agente' do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:account_user) { account.account_users.find_by(user: agent) }
  let(:so_chat) { Staydesk::AgentStatus.create!(account: account, name: 'Só chat', availability: 'online', offline_after_seconds: 120) }
  let(:servico) { Staydesk::AgentStatusService.new(account_user) }

  def presenca(online)
    allow(OnlineStatusTracker).to receive(:get_presence).and_return(online)
  end

  it 'keeps the status while the person is connected and stamps the presence' do
    servico.change_to(so_chat, at: 10.minutes.ago)
    presenca(true)

    Staydesk::AgentStatuses::DisconnectJob.new.perform

    periodo = Staydesk::AgentStatusPeriod.current.find_by(account_user: account_user)
    expect(periodo).to be_present
    expect(periodo.last_connected_at).to be_within(5.seconds).of(Time.current)
  end

  it 'drops the status once the person is gone past the limit' do
    servico.change_to(so_chat, at: 10.minutes.ago)
    presenca(false)

    Staydesk::AgentStatuses::DisconnectJob.new.perform

    expect(servico.current).to be_nil
    expect(account_user.reload.availability).to eq('offline')
  end

  it 'waits for the limit, counted from the last sign of life' do
    servico.change_to(so_chat, at: 10.minutes.ago)
    periodo = Staydesk::AgentStatusPeriod.current.find_by(account_user: account_user)
    servico.registrar_presenca!(periodo, at: 30.seconds.ago)
    presenca(false)

    Staydesk::AgentStatuses::DisconnectJob.new.perform

    expect(servico.current).to eq(so_chat)
  end

  it 'falls into the target status when the status has one' do
    ausente = Staydesk::AgentStatus.create!(account: account, name: 'Ausente', availability: 'busy', offline_after_seconds: nil)
    so_chat.update!(offline_to_status: ausente)
    servico.change_to(so_chat, at: 10.minutes.ago)
    presenca(false)

    Staydesk::AgentStatuses::DisconnectJob.new.perform

    expect(servico.current).to eq(ausente)
    expect(account_user.reload.availability).to eq('busy')
  end

  it 'never drops a status with no limit' do
    sem_limite = Staydesk::AgentStatus.create!(account: account, name: 'Plantão', availability: 'online', offline_after_seconds: nil)
    servico.change_to(sem_limite, at: 2.days.ago)
    presenca(false)

    Staydesk::AgentStatuses::DisconnectJob.new.perform

    expect(servico.current).to eq(sem_limite)
  end

  it 'refuses a status pointing at itself or at another account' do
    outra = create(:account)
    alheio = Staydesk::AgentStatus.create!(account: outra, name: 'Fora', availability: 'busy')

    expect(so_chat.tap { |s| s.offline_to_status = so_chat }).not_to be_valid
    expect(so_chat.tap { |s| s.offline_to_status = alheio }).not_to be_valid
  end

  it 'keeps the availability the distribution reads in step with the status' do
    allow(OnlineStatusTracker).to receive(:set_status)

    servico.change_to(so_chat)
    expect(OnlineStatusTracker).to have_received(:set_status).with(account.id, agent.id, 'online')

    presenca(false)
    servico.change_to(so_chat, at: 10.minutes.ago)
    Staydesk::AgentStatuses::DisconnectJob.new.perform
    expect(OnlineStatusTracker).to have_received(:set_status).with(account.id, agent.id, 'offline')
  end
end
