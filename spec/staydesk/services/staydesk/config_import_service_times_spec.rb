require 'rails_helper'

# Pôr muita gente em muitos grupos é trabalho de arquivo, não de clique: o
# grupo pode declarar quem está nele e o importador resolve por e-mail.
RSpec.describe Staydesk::ConfigImportService do
  let(:account) { create(:account) }
  before do
    create(:user, account: account, email: 'ana@staycloud.com', role: :agent)
    create(:user, account: account, email: 'bruno@staycloud.com', role: :agent)
  end

  def importar(times)
    described_class.new(account: account, config: { 'times' => times }).perform
  end

  def membros(nome)
    account.teams.find_by('lower(name) = ?', nome.downcase).members.pluck(:email).sort
  end

  it 'still accepts a plain list of names' do
    importar(['Suporte N1', 'Suporte N2'])

    expect(account.teams.pluck(:name)).to eq(['Suporte N1', 'Suporte N2'])
  end

  it 'puts the agents into the group by e-mail' do
    importar([{ 'nome' => 'Suporte N1', 'agentes' => ['ana@staycloud.com', 'BRUNO@staycloud.com'] }])

    expect(membros('Suporte N1')).to eq(['ana@staycloud.com', 'bruno@staycloud.com'])
  end

  it 'adds without removing who was already there' do
    importar([{ 'nome' => 'Suporte N1', 'agentes' => ['ana@staycloud.com'] }])
    importar([{ 'nome' => 'Suporte N1', 'agentes' => ['bruno@staycloud.com'] }])

    expect(membros('Suporte N1')).to eq(['ana@staycloud.com', 'bruno@staycloud.com'])
  end

  it 'mirrors the list exactly when asked to' do
    importar([{ 'nome' => 'Suporte N1', 'agentes' => %w[ana@staycloud.com bruno@staycloud.com] }])
    importar([{ 'nome' => 'Suporte N1', 'agentes' => ['ana@staycloud.com'], 'agentes_exatos' => true }])

    expect(membros('Suporte N1')).to eq(['ana@staycloud.com'])
  end

  it 'says who is not in the account instead of failing' do
    resumo = importar([{ 'nome' => 'Suporte N1', 'agentes' => ['ana@staycloud.com', 'ninguem@staycloud.com'] }])

    expect(resumo[:times].first).to include('sem conta: ninguem@staycloud.com')
    expect(membros('Suporte N1')).to eq(['ana@staycloud.com'])
  end

  it 'runs twice without piling up members' do
    2.times { importar([{ 'nome' => 'Suporte N1', 'agentes' => ['ana@staycloud.com'] }]) }

    expect(membros('Suporte N1')).to eq(['ana@staycloud.com'])
  end
end
