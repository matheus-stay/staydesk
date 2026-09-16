# Edição community do StayDesk: o job diário de versão é o que liga para o hub do
# Chatwoot (hub.2.chatwoot.com) com host, versão e edição da instância. No núcleo,
# DISABLE_TELEMETRY só tira as métricas do payload; aqui ele zera o job inteiro.
module Custom::Internal::CheckNewVersionsJob
  def perform
    return if ENV.fetch('DISABLE_TELEMETRY', false)

    super
  end
end
