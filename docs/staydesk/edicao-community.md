# StayDesk — Edição community, sem recursos pagos

O StayDesk roda a edição community (MIT) do Chatwoot. Nada da pasta `enterprise/` executa, nenhum
recurso premium aparece e a instância não liga para o Chatwoot. A pasta continua no repositório
porque o sync com o oficial precisa dela.

## Ambiente

| Variável | Valor | Efeito |
|---|---|---|
| `DISABLE_ENTERPRISE` | `true` | `ChatwootApp.enterprise?` fica falso: ganchos `Enterprise::` não entram, rotas `/enterprise/api` somem, `isEnterprise` fica falso no front e o plano vira `community`. Como toda rota premium exige instalação cloud ou enterprise, SLA, papéis, auditoria, SAML, empresas, cobrança, chamadas e Captain saem da barra lateral |
| `DISABLE_TELEMETRY` | `true` | No núcleo só tira as métricas do payload do hub; com a camada, zera o job diário inteiro (abaixo) |

## O que a camada faz

- `custom/config/boot.rb` corrige `ChatwootApp.extensions`: no núcleo, a simples existência de `custom/`
  devolve `%w[enterprise custom]` e injeta os módulos Enterprise mesmo com `DISABLE_ENTERPRISE`.
  Com a correção, `enterprise` só entra na lista quando `ChatwootApp.enterprise?` é verdadeiro.
- `Custom::Internal::CheckNewVersionsJob` não executa o job diário de versão quando `DISABLE_TELEMETRY` está
  definido: é ele que chama `ChatwootHub.sync_with_hub`. Sem ele também some a faixa "nova versão do Chatwoot".
- `custom/config/initializers/audited.rb` devolve a classe de auditoria ao padrão da gem.
- `bundle exec rails staydesk:setup` liga `disable_branding` em todas as contas. É flag comum de
  conta, sem dependência do Enterprise: tira o "Powered by" do widget e do portal.

## Conferindo

- `GET /enterprise/api/v1/...` responde 404.
- Barra lateral sem SLA, papéis personalizados, auditoria, Captain, empresas e cobrança.
- `GET /api/v1/accounts/:id` devolve `features` sem recurso premium ligado além de `disable_branding`.
- Log de rede do servidor sem chamada para `hub.2.chatwoot.com`.
- Super admin mostra plano `community`.

## Fora da imagem (opcional, por último)

Uma linha `enterprise/` no `.dockerignore` deixa a pasta fora do container. Validar em ambiente de teste
antes: `config/application.rb` referencia os caminhos de `enterprise/` sem checar se existem.
