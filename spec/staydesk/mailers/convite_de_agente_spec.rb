require 'rails_helper'

# O convite de agente morria calado: o produto deixa as telas da edição paga na
# frente das do núcleo mesmo com ela desligada, e o modelo de e-mail de
# confirmação chama um recurso que só existe lá. O agente era criado, o e-mail
# nunca saía, e nada aparecia na interface.
RSpec.describe 'convite de agente' do
  let(:account) { create(:account) }
  let(:convidado) { create(:user, account: account, email: 'convidado@staycloud.com') }

  it 'does not keep the paid edition views in front when the edition is off' do
    skip 'a edição paga está ligada neste ambiente' if ChatwootApp.enterprise?

    caminhos = Rails.application.config.paths['app/views'].to_a

    expect(caminhos).to be_none { |caminho| caminho.end_with?('enterprise/app/views') }
  end

  # Antes isto levantava ActionView::Template::Error no envio, e o convite
  # sumia sem deixar rastro na tela.
  it 'renders the confirmation e-mail instead of blowing up on a paid-edition method' do
    Current.account = account
    mail = Devise::Mailer.with(account: account).confirmation_instructions(convidado, 'token-de-teste')

    expect { mail.body.encoded }.not_to raise_error
    expect(mail.body.encoded).to be_present
    expect(mail.to).to eq(['convidado@staycloud.com'])
  ensure
    Current.reset
  end

  it 'asks for the confirmation e-mail when an agent is invited' do
    Current.account = account
    convite = AgentBuilder.new(email: 'novo@staycloud.com', name: 'Novo', inviter: create(:user, account: account),
                               account: account, role: :agent)

    convidados = []
    allow_any_instance_of(User).to receive(:send_confirmation_instructions) { |user| convidados << user.email } # rubocop:disable RSpec/AnyInstance
    convite.perform

    expect(convidados).to eq(['novo@staycloud.com'])
  ensure
    Current.reset
  end
end
