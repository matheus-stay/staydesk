# StayDesk — Camada própria e toques no núcleo

Como o StayDesk acrescenta código ao Chatwoot sem transformar o sync com o oficial numa sessão de conflitos.

## Onde cada coisa vive

| Camada | Pasta | Como entra no Chatwoot |
|---|---|---|
| Backend próprio | `custom/` | Autoload, views, initializers, migrations, rake e rotas registrados por `custom/config/boot.rb`, chamado em duas linhas de `config/application.rb`; módulos `Custom::` entram pelo gancho `prepend_mod_with` que o núcleo já tem. Detalhe em `custom/README.md` |
| Frontend próprio | `app/javascript/staydesk/` | Plugin `app.use(StayDesk, { i18n })` em `entrypoints/dashboard.js`; rotas por spread em `dashboard/routes/index.js`; textos por `mergeLocaleMessage` nos três entrypoints; alias `staydesk` em `vite.shared` |
| Tokens e marca | `theme/`, `tailwind.config.js`, `public/brand-assets/`, `InstallationConfig` | Pontos de extensão que o próprio Chatwoot oferece |
| Testes | `spec/staydesk/`, `app/javascript/staydesk/**/specs/` | Rodam com a suíte normal |

## As quatro formas de tocar arquivo do núcleo

| Tipo | O que é | Limite |
|---|---|---|
| `classe` | Troca de classe Tailwind em componente do upstream | Só classe; a linha sem o atributo `class` fica idêntica |
| `gancho` | Uma linha que chama composable ou componente da camada, com `staydesk` no texto | Uma linha; a lógica fica em `app/javascript/staydesk/` |
| `montagem` | Import ou uso único da camada nos arquivos de entrada | Lista fixa, abaixo |
| `view` | Partial ERB copiada para `custom/app/views` no mesmo caminho relativo | Só ERB pequena; o original não muda |

Copiar um componente Vue do upstream para editar **não é permitido**: a cópia diverge a cada sync.
Se um componente não dá para compor nem para ganchar com uma linha, isso é decisão de arquitetura, não atalho.

Todo toque fica registrado em `core-touches.md` e é verificado por `node custom/bin/staydesk-gate.mjs`,
que roda no CI (`.github/workflows/staydesk_gate.yml`) e localmente. Arquivos herdados do ramo de UX,
editados no lugar antes desta regra, estão registrados como `legado`: não são checados e devem ser
migrados aos poucos para classe-só ou para a camada.

## Pontos de montagem (fixos)

| Arquivo | Linha |
|---|---|
| `config/application.rb` | Duas linhas: `require_relative` de `custom/config/boot.rb` e `StaydeskBoot.configure(config)` |
| `vite.shared.ts` | Alias `staydesk` |
| `app/javascript/entrypoints/dashboard.js` | `app.use(StayDesk, { i18n })` |
| `app/javascript/entrypoints/widget.js` | `mergeStaydeskWidgetMessages(i18n)` |
| `app/javascript/entrypoints/survey.js` | `mergeStaydeskSurveyMessages(i18n)` |
| `app/javascript/dashboard/routes/index.js` | `...staydeskRoutes` |

## Rodando

```bash
node custom/bin/staydesk-gate.mjs            # gate contra develop (espelho do oficial)
node custom/bin/marca.mjs varredura          # nenhum texto visível diz Chatwoot (docs marca.md)
pnpm exec vitest --no-watch app/javascript/staydesk
bundle exec rspec spec/staydesk
```
