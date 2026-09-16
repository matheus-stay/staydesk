# StayDesk — Marca (nome, textos e ícones)

Onde estiver escrito "Chatwoot" para alguém ver, está "StayDesk"; o favicon e os ícones do app são os
da Stay. Identificadores de código não mudam. Quase tudo se resolve pelo mecanismo de marca que o
Chatwoot já tem (`InstallationConfig`); o resto vive na camada StayDesk.

## 1. Configuração (`rails staydesk:setup`)

`Staydesk::SetupService` grava, idempotente, em `InstallationConfig`:

| Chave | Valor | Cobre |
|---|---|---|
| `INSTALLATION_NAME`, `BRAND_NAME` | StayDesk | Título da aba, meta description, textos que passam por `useBranding`, rodapé de e-mails e do portal, "Powered by"; e desliga qualquer paywall (`isACustomBrandedInstance`) |
| `BRAND_URL`, `WIDGET_BRAND_URL` | `STAYDESK_BRAND_URL` (padrão `https://staycloud.com.br`) | Links de marca no portal e no widget |
| `TERMS_URL`, `PRIVACY_URL` | `STAYDESK_TERMS_URL`, `STAYDESK_PRIVACY_URL` (padrão: a URL da marca) | Termos e privacidade no cadastro e no rodapé |

E liga `disable_branding` em todas as contas (flag comum, sem Enterprise): sem "Powered by" no widget e no portal.

`LOGO`, `LOGO_DARK` e `LOGO_THUMBNAIL` já apontam para os SVG de `public/brand-assets/`, trocados pelo
ramo de UX. `DISPLAY_MANIFEST` fica ligado: é o que inclui favicons e manifesto na página.
O remetente de e-mail vem de `MAILER_SENDER_EMAIL` no ambiente (`StayDesk <endereço>`).

## 2. Ícones

- Fonte: `public/brand-assets/icon.svg` (o ícone da Stay).
- `node custom/bin/icones/gerar.mjs` regrava em `public/`: `favicon` 16/32/96/512, `favicon-badge` 16/32/96
  (com o ponto vermelho que `faviconHelper.js` mostra em mensagem nova), `apple-icon` 57 a 180 mais
  `apple-icon.png`, `apple-touch-icon*.png`, `android-icon` 36 a 192 e `ms-icon` 70/144/150/310.
  Depende de `@resvg/resvg-js`, instalado à parte: `pnpm --dir custom/bin/icones install --ignore-workspace`.
- `public/manifest.json` (nome, cores) e `public/browserconfig.xml` (cor do tile) editados à mão.

Arquivo em `public/` é o único caso de "editar" arquivo do upstream sem gancho: é binário, e no sync a
versão que vale é a nossa.

## 3. Textos

O Chatwoot troca "Chatwoot" pelo `INSTALLATION_NAME` só nos textos que passam por `useBranding`. O
resto é fixo nos dicionários. A camada mescla sobreposições por cima, sem editar JSON do upstream:

- `app/javascript/staydesk/i18n/overrides/{dashboard,widget,survey}/{en,pt_BR}.json`, aplicados por
  `mergeLocaleMessage` nos entrypoints (SPEC-00). **Gerados**, não escritos à mão:
  `node custom/bin/marca.mjs gerar` lê os dicionários do upstream, acha toda folha visível com
  "Chatwoot" e grava a versão StayDesk. Rodar depois de cada sync.
- `custom/config/locales/{en,pt_BR}.yml`: as chaves do backend (descrições de integrações), mescladas
  pelo Rails por cima das originais.
- `custom/app/views/**`: partials ERB sobrepostas onde o texto é fixo no HTML (login e menu do super
  admin). O título do super admin vem da gem Administrate e é trocado em
  `custom/config/initializers/super_admin_branding.rb`.

`node custom/bin/marca.mjs varredura` falha quando sobra texto visível com "Chatwoot" sem sobreposição
(dicionários, `config/locales`, views ERB e Liquid). Roda no CI junto com o gate.

## 4. Tema claro por padrão

O Chatwoot sem preferência guardada segue o sistema operacional. O StayDesk nasce claro: na primeira
visita o plugin grava `light` na preferência local (`app/javascript/staydesk/config/theme.js`). A escolha
do usuário em Perfil › Aparência (claro, escuro ou automático) continua valendo depois disso.

## 5. O que nunca se renomeia

Contratos de código: `window.chatwootSDK`, `window.$chatwoot`, `window.chatwootSettings`
(SDK do widget nos sites dos clientes), o cookie `cw_conversation`, o módulo `Chatwoot` do Rails,
`ChatwootApp`, `ChatwootHub`, `ChatwootExceptionTracker`, o pacote `@chatwoot/chatwoot`, a tarefa
`db:chatwoot_prepare`, as variáveis `CHATWOOT_*`, nomes de tabela e de fila. A varredura já os ignora.
