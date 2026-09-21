require 'rails_helper'

# No Zendesk o grupo aparece como foi escrito. O produto passava tudo para
# minúsculas, e "suporte n1" na barra lateral não é o que a operação escreveu.
RSpec.describe Team do
  let(:account) { create(:account) }

  it 'keeps the name as it was typed' do
    expect(described_class.create!(account: account, name: 'Suporte N1').name).to eq('Suporte N1')
  end

  it 'still trims spaces and control characters' do
    expect(described_class.create!(account: account, name: "  Tech Lead \n").name).to eq('Tech Lead')
  end

  it 'refuses another group whose name differs only in case' do
    described_class.create!(account: account, name: 'Suporte N1')
    repetido = described_class.new(account: account, name: 'suporte n1')

    expect(repetido).not_to be_valid
  end

  it 'lets the same name live in another account' do
    described_class.create!(account: account, name: 'Suporte N1')

    expect(described_class.new(account: create(:account), name: 'Suporte N1')).to be_valid
  end
end
