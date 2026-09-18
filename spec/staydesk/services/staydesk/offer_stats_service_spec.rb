require 'rails_helper'

RSpec.describe Staydesk::OfferStatsService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let!(:ana) { create(:user, account: account, role: :agent, name: 'Ana') }

  def convite(status, criado_em: 1.hour.ago, respondido_em: nil)
    Staydesk::Offer.create!(account_id: account.id, user: ana, conversation: create(:conversation, account: account, inbox: inbox),
                            status: status, expires_at: criado_em + 30.seconds,
                            created_at: criado_em, answered_at: respondido_em)
  end

  it 'counts the offers, the acceptance rate and how long the agent takes to answer' do
    convite('aceita', criado_em: 2.hours.ago, respondido_em: 2.hours.ago + 8.seconds)
    convite('aceita', criado_em: 1.hour.ago, respondido_em: 1.hour.ago + 12.seconds)
    convite('expirada')
    convite('recusada')

    linha = described_class.new(account).perform.find { |item| item[:user_id] == ana.id }

    expect(linha).to include(offers: 4, accepted: 2, declined: 1, expired: 1, acceptance_rate: 50.0)
    expect(linha[:average_answer_seconds]).to eq(10)
  end

  it 'leaves the rate empty for whoever received nothing in the window' do
    linha = described_class.new(account).perform.find { |item| item[:user_id] == ana.id }

    expect(linha).to include(offers: 0, acceptance_rate: nil)
  end
end
