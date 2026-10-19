require 'rails_helper'

# Quais campos travam o encerramento do ticket é configuração da operação:
# entra pelo arquivo, como o resto.
RSpec.describe Staydesk::ConfigImportService do
  let(:account) { create(:account) }

  def importar(atributos)
    described_class.new(account: account, config: { 'atributos' => atributos }).perform
  end

  def campo(chave)
    account.custom_attribute_definitions.find_by(attribute_key: chave)
  end

  it 'marks a field as required to resolve from the file' do
    importar([{ 'chave' => 'tipo_de_demanda', 'nome' => 'Tipo de Demanda', 'tipo' => 'list', 'valores' => %w[dúvidas bugs],
                'obrigatorio_para_resolver' => true }])

    expect(campo('tipo_de_demanda').staydesk_required_to_resolve).to be(true)
  end

  it 'keeps what was marked on screen when the file does not say' do
    importar([{ 'chave' => 'servidor', 'nome' => 'Servidor', 'obrigatorio_para_resolver' => true }])
    importar([{ 'chave' => 'servidor', 'nome' => 'Servidor' }])

    expect(campo('servidor').staydesk_required_to_resolve).to be(true)
  end
end
