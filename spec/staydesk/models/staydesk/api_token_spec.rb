require 'rails_helper'

RSpec.describe Staydesk::ApiToken do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :agent) }

  def gerar(scopes)
    described_class.gerar!(account: account, user: user, name: 'Integração', scopes: scopes)
  end

  it 'shows the value once and keeps only the digest' do
    token = gerar(['relatorios:leitura'])

    expect(token.token_em_claro).to start_with('sd_')
    expect(token.token_digest).not_to include(token.token_em_claro)
    expect(described_class.find(token.id).token_em_claro).to be_nil
    expect(token.token_hint).to eq(token.token_em_claro.last(4))
  end

  it 'finds the token by its value and refuses anything else' do
    token = gerar(['relatorios:leitura'])

    expect(described_class.autenticar(token.token_em_claro)).to eq(token)
    expect(described_class.autenticar('sd_naoexiste')).to be_nil
    expect(described_class.autenticar(nil)).to be_nil
  end

  it 'refuses a suspended or expired token' do
    token = gerar(['relatorios:leitura'])
    valor = token.token_em_claro

    token.update!(active: false)
    expect(described_class.autenticar(valor)).to be_nil

    token.update!(active: true, expires_at: 1.minute.ago)
    expect(described_class.autenticar(valor)).to be_nil
  end

  it 'refuses a scope that is not in the catalog' do
    token = described_class.new(account: account, user: user, name: 'X', scopes: ['voar:leitura'],
                                token_digest: 'a', token_hint: 'a')

    expect(token).not_to be_valid
    expect(token.errors[:scopes].join).to include('voar:leitura')
  end

  describe 'what each scope reaches' do
    it 'separates reading from writing' do
      token = gerar(['operacao:leitura'])

      expect(token.autoriza?('api/v1/accounts/staydesk/queues', 'GET')).to be(true)
      expect(token.autoriza?('api/v1/accounts/staydesk/queues', 'POST')).to be(false)
    end

    it 'does not let one area open another' do
      token = gerar(['relatorios:leitura'])

      expect(token.autoriza?('api/v1/accounts/staydesk/kpis', 'GET')).to be(true)
      expect(token.autoriza?('api/v1/accounts/conversations', 'GET')).to be(false)
    end

    it 'keeps the most specific group when prefixes overlap' do
      expect(Staydesk::ApiScope.grupo_de('api/v1/accounts/staydesk/kpis')).to eq('relatorios')
      expect(Staydesk::ApiScope.grupo_de('api/v1/accounts/staydesk/queues')).to eq('operacao')
      expect(Staydesk::ApiScope.grupo_de('api/v1/accounts/conversations/messages')).to eq('conversas')
      expect(Staydesk::ApiScope.grupo_de('api/v1/accounts/webhooks')).to eq('automacao')
    end

    it 'closes the door on an endpoint no group covers' do
      token = gerar(['conta:leitura', 'conta:escrita'])

      expect(Staydesk::ApiScope.exigido('api/v1/outra_coisa', 'GET')).to be_nil
      expect(token.autoriza?('api/v1/outra_coisa', 'GET')).to be(false)
    end
  end
end
