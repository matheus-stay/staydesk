require 'rails_helper'

RSpec.describe 'fechou a aba, saiu do status', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:account_user) { account.account_users.find_by(user: agent) }
  let(:servico) { Staydesk::AgentStatusService.new(account_user) }
  # Sem tempo limite: o status nunca cairia sozinho. Fechar a aba derruba mesmo assim.
  let(:so_chat) { Staydesk::AgentStatus.create!(account: account, name: 'Só chat', availability: 'online', offline_after_seconds: nil) }

  def presenca(online)
    allow(OnlineStatusTracker).to receive(:get_presence).and_return(online)
  end

  def fechar_aba
    post "/api/v1/accounts/#{account.id}/staydesk/agent_status_periods/leave", headers: agent.create_new_auth_token, as: :json
  end

  it 'waits for the presence to lapse before acting on the closed tab' do
    expect { fechar_aba }.to have_enqueued_job(Staydesk::AgentStatuses::LeaveJob).with(account_user.id)
    expect(response).to have_http_status(:accepted)
  end

  it 'goes offline when no tab is left, even on a status with no time limit' do
    servico.change_to(so_chat)
    presenca(false)

    Staydesk::AgentStatuses::LeaveJob.perform_now(account_user.id)

    expect(servico.current).to be_nil
    expect(account_user.reload.availability).to eq('offline')
  end

  it 'keeps the status when another tab is still connected, or the page was only reloaded' do
    servico.change_to(so_chat)
    presenca(true)

    Staydesk::AgentStatuses::LeaveJob.perform_now(account_user.id)

    expect(servico.current).to eq(so_chat)
  end

  it 'lets the agent go offline by hand and stay there' do
    servico.change_to(so_chat)

    post "/api/v1/accounts/#{account.id}/staydesk/agent_status_periods/offline", headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
    expect(response.parsed_body['current_status_id']).to be_nil
    expect(servico.current).to be_nil
    expect(account_user.reload.availability).to eq('offline')
  end
end
