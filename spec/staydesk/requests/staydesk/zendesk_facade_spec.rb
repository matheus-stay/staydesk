require 'rails_helper'

# A fachada tem que responder como o Zendesk responde ao sync do dashboard.
RSpec.describe 'StayDesk Zendesk facade', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agente) { create(:user, account: account, role: :agent) }
  let!(:n1) { create(:team, account: account, name: 'suporte n1') }
  let(:chat) { create(:inbox, account: account) }
  let(:token) do
    Staydesk::ApiToken.gerar!(account: account, user: admin, name: 'Dashboard',
                              scopes: %w[relatorios:leitura conversas:leitura conversas:escrita])
  end
  let(:basic) { { 'Authorization' => "Basic #{Base64.strict_encode64("#{admin.email}/token:#{token.token_em_claro}")}" } }
  let(:base) { '/staydesk/zendesk/api/v2' }

  before { create(:team_member, team: n1, user: agente) }

  def conversa(**extras)
    create(:conversation, account: account, inbox: chat, team: n1, assignee: agente, **extras).tap do |c|
      create(:message, account: account, inbox: chat, conversation: c, message_type: :incoming, content: 'Meu site caiu', sender: c.contact)
    end
  end

  it 'refuses without a token and with a token that lacks the scope' do
    get "#{base}/groups.json"
    expect(response).to have_http_status(:unauthorized)

    fraco = Staydesk::ApiToken.gerar!(account: account, user: admin, name: 'Só conversas', scopes: %w[conversas:leitura])
    get "#{base}/groups.json", headers: { 'api_access_token' => fraco.token_em_claro }
    expect(response).to have_http_status(:unauthorized)
  end

  it 'exports tickets incrementally by cursor with users, groups and metric sets' do
    antiga = conversa
    antiga.update_columns(updated_at: 2.days.ago)
    nova = conversa(priority: :urgent)

    get "#{base}/incremental/tickets/cursor.json",
        params: { start_time: 1.day.ago.to_i, include: 'metric_sets,users,groups', per_page: 1 }, headers: basic

    expect(response).to have_http_status(:success)
    corpo = response.parsed_body
    expect(corpo['tickets'].map { |t| t['id'] }).to eq([nova.display_id])
    ticket = corpo['tickets'].first
    expect(ticket).to include('status' => 'new', 'priority' => 'urgent', 'assignee_id' => agente.id, 'group_id' => n1.id,
                              'requester_id' => 1_000_000_000 + nova.contact_id, 'description' => 'Meu site caiu')
    expect(ticket['via']).to include('channel' => 'chat')
    expect(ticket['metric_set']).to include('ticket_id' => nova.display_id, 'replies' => 0)
    expect(corpo['users'].map { |u| u['role'] }).to include('admin', 'agent', 'end-user')
    expect(corpo['groups'].first).to include('name' => 'suporte n1')
    expect(corpo['ticket_metric_sets'].size).to eq(1)
    expect(corpo['end_of_stream']).to be(true)
    expect(corpo['after_cursor']).to be_present
  end

  it 'lists users, groups, ticket fields and agent availabilities' do
    definicao = create(:custom_attribute_definition, account: account, attribute_model: 'conversation_attribute',
                                                     attribute_key: 'tipo_de_demanda', attribute_display_name: 'Tipo', attribute_display_type: 'list',
                                                     attribute_values: %w[Bug Dúvida])
    status = Staydesk::AgentStatus.create!(account: account, name: 'Só chat', availability: 'online', work_channels: %w[chat])
    Staydesk::AgentStatusService.new(account.account_users.find_by(user: agente)).change_to(status)

    get "#{base}/users.json", params: { role: %w[admin agent] }, headers: basic
    expect(response.parsed_body['users'].map { |u| u['id'] }).to contain_exactly(admin.id, agente.id)

    get "#{base}/groups", headers: basic
    expect(response.parsed_body['groups'].map { |g| g['name'] }).to eq(['suporte n1'])

    get "#{base}/ticket_fields.json", headers: basic
    campo = response.parsed_body['ticket_fields'].find { |f| f['id'] == definicao.id }
    expect(campo).to include('type' => 'tagger', 'title' => 'Tipo')
    expect(campo['custom_field_options'].map { |o| o['value'] }).to eq(%w[Bug Dúvida])

    get "#{base}/agent_availabilities/agent_statuses", headers: basic
    expect(response.parsed_body['data'].map { |d| d['attributes']['name'] }).to include('Online', 'Offline', 'Só chat')

    get "#{base}/agent_availabilities", params: { page: { size: 100 } }, headers: basic
    linha = response.parsed_body['data'].find { |d| d['attributes']['agent_id'] == agente.id }
    expect(linha['id']).to eq("agent_availabilities|#{agente.id}")
    expect(linha['attributes']['agent_status']).to include('name' => 'Só chat')
    expect(linha['attributes']['channels']).to include('messaging' => 'online', 'support' => 'offline')
  end

  it 'serves satisfaction ratings with cursor pagination' do
    c1 = conversa
    c2 = conversa
    [c1, c2].each_with_index do |c, i|
      CsatSurveyResponse.create!(account: account, conversation: c, message: c.messages.first, contact: c.contact,
                                 assigned_agent: agente, rating: 5 - (i * 3), feedback_message: i.zero? ? 'ótimo' : nil)
    end

    get "#{base}/satisfaction_ratings.json", params: { start_time: 1.day.ago.to_i, sort_order: 'asc', page: { size: 1 } }, headers: basic
    corpo = response.parsed_body
    expect(corpo['satisfaction_ratings'].first).to include('ticket_id' => c1.display_id, 'score' => 'good_with_comment', 'assignee_id' => agente.id)
    expect(corpo['meta']['has_more']).to be(true)
    expect(corpo['links']['next']).to include('page%5Bafter%5D=')

    get corpo['links']['next'], headers: basic
    expect(response.parsed_body['satisfaction_ratings'].first).to include('ticket_id' => c2.display_id, 'score' => 'bad')
    expect(response.parsed_body['meta']['has_more']).to be(false)
  end

  it 'updates a ticket like the escalation does: status, tags and a private comment' do
    c = conversa

    put "#{base}/tickets/#{c.display_id}.json",
        params: { ticket: { status: 'pending', tags: %w[escalado], comment: { body: 'Escalado para o N3', public: false } } },
        headers: basic, as: :json

    expect(response).to have_http_status(:success)
    expect(response.parsed_body['ticket']).to include('status' => 'pending', 'tags' => ['escalado'])
    expect(c.reload.messages.last).to have_attributes(content: 'Escalado para o N3', private: true)

    get "#{base}/tickets/#{c.display_id}/comments.json", headers: basic
    expect(response.parsed_body['comments'].map { |m| m['public'] }).to eq([true, false])

    post "#{base}/tickets/#{c.display_id}/tags.json", params: { tags: %w[urgente] }, headers: basic, as: :json
    expect(response.parsed_body['tags']).to contain_exactly('escalado', 'urgente')

    get "#{base}/users/search.json", params: { query: c.contact.email }, headers: basic
    expect(response.parsed_body['users'].first['id']).to eq(1_000_000_000 + c.contact_id)

    get "#{base}/users/#{1_000_000_000 + c.contact_id}/tickets/requested.json", headers: basic
    expect(response.parsed_body['tickets'].map { |t| t['id'] }).to eq([c.display_id])
  end

  it 'emits SLA metric events from the applied SLA' do
    c = conversa
    politica = Staydesk::SlaPolicy.create!(account: account, name: 'SLA chat',
                                           targets: { 'default' => { 'first_response' => 5, 'resolution' => 60 } })
    Staydesk::AppliedSla.create!(account: account, conversation: c, sla_policy: politica,
                                 first_response_due_at: 5.minutes.from_now, first_response_met_at: 2.minutes.from_now,
                                 resolution_due_at: 1.hour.from_now, breached_metrics: [])

    get "#{base}/incremental/ticket_metric_events.json", params: { start_time: 1.day.ago.to_i }, headers: basic
    eventos = response.parsed_body['ticket_metric_events']
    expect(eventos.map { |e| [e['metric'], e['type']] }).to include(%w[reply_time apply_sla], %w[reply_time fulfill], %w[resolution_time apply_sla])
    expect(eventos.first['sla']['policy']).to include('title' => 'SLA chat')
  end
end
