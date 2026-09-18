# Registro de toques no núcleo

Todo arquivo do Chatwoot (fora de `custom/`, `app/javascript/staydesk/`, `docs/staydesk/`, `spec/staydesk/`,
`swagger/staydesk/`, tokens e ícones) que o StayDesk altera está listado aqui, com o tipo do toque. O gate
(`node custom/bin/staydesk-gate.mjs`) lê esta tabela: arquivo alterado e não listado é violação;
arquivo listado é checado conforme o tipo. Regras em `camada-staydesk.md`.

Tipos: `montagem` (ponto de entrada da camada, lista fixa), `gancho` (uma linha que chama a camada),
`classe` (só classe Tailwind), `view` (partial sobreposta em `custom/app/views`; o original não muda),
`legado` (edição no lugar herdada do ramo de UX; não é checada e deve ser migrada).

## Montagem e ganchos

| Arquivo | Tipo | Spec | Motivo |
|---|---|---|---|
| `config/application.rb` | montagem | SPEC-00 | Chama `custom/config/boot.rb`, que registra os caminhos de `custom/` |
| `vite.shared.ts` | montagem | SPEC-00 | Alias `staydesk` |
| `app/javascript/entrypoints/dashboard.js` | montagem | SPEC-00 | Plugin da camada com os textos do dashboard |
| `app/javascript/entrypoints/widget.js` | montagem | SPEC-00 | Textos StayDesk do widget |
| `app/javascript/entrypoints/survey.js` | montagem | SPEC-00 | Textos StayDesk da pesquisa de satisfação |
| `app/javascript/dashboard/routes/index.js` | montagem | SPEC-00 | Rotas da camada, injetadas como filhas da rota da conta por `withStaydeskRoutes` |
| `app/javascript/dashboard/components-next/sidebar/Sidebar.vue` | gancho | SPEC-03 | Central de administração abre em aba própria (2 linhas) |
| `tailwind.config.js` | gancho | UX | A camada StayDesk entra no scan do Tailwind (2 linhas) |
| `app/controllers/concerns/access_token_auth_helper.rb` | gancho | API | Token de API do StayDesk entra na autenticação (1 linha) |
| `lib/current.rb` | gancho | API | O token de API do pedido viaja em Current (2 linhas) |
| `app/controllers/api/v1/accounts/custom_attribute_definitions_controller.rb` | gancho | Campos | Permite `staydesk_required_to_resolve` (1 linha) |
| `app/views/api/v1/models/_custom_attribute_definition.json.jbuilder` | view | Campos | Sobreposição em `custom/app/views` com a marcação de obrigatório |
| `app/javascript/dashboard/routes/dashboard/settings/attributes/AddAttribute.vue` | montagem | Campos | Chave de obrigatório para resolver no formulário |
| `app/javascript/dashboard/routes/dashboard/settings/attributes/EditAttribute.vue` | montagem | Campos | Chave de obrigatório para resolver no formulário |
| `app/javascript/dashboard/routes/dashboard/conversation/contact/ContactInfo.vue` | gancho | UX | O nome do cliente abre o perfil; a edição fica no lápis |
| `app/javascript/dashboard/routes/dashboard/settings/inbox/Settings.vue` | gancho | Canais | A aba Colaboradores sai: todo agente atende todos os canais (2 linhas) |
| `app/services/auto_assignment/agent_assignment_service.rb` | gancho | SPEC-16 | `prepend_mod_with` para a fila com aceite convidar em vez de atribuir (1 linha) |
| `spec/support/staydesk_inbox_members.rb` | legado | Canais | Arquivo novo: `create(:inbox_member)` de vínculo que já existe devolve o existente, porque todo agente já está em todos os canais |
| `app/javascript/dashboard/components-next/sidebar/Sidebar.vue` | montagem | UX | Botão de compactar a barra lateral |
| `app/javascript/dashboard/components-next/sidebar/Sidebar.vue` | montagem | UX | Rodapé da barra (compactar e Central) fora da parte que rola |
| `app/javascript/dashboard/components-next/sidebar/SidebarGroup.vue` | gancho | UX | Passa `to` ao subgrupo (1 linha) |
| `app/javascript/dashboard/components-next/sidebar/SidebarSubGroup.vue` | gancho | UX | Prop `to` e repasse ao separador (2 linhas) |
| `app/javascript/dashboard/components-next/sidebar/SidebarGroupSeparator.vue` | legado | UX | Com `to`, o nome da seção vira link e só a seta recolhe; troca de bloco no template, além de uma linha |
| `app/javascript/dashboard/components-next/sidebar/provider.js` | gancho | UX | Largura padrão da barra sobe para 264 (1 linha) |
| `app/javascript/dashboard/components-next/sidebar/Sidebar.vue` | gancho | UX | O grupo "Mais" some quando não tem item (1 linha) |
| `app/javascript/dashboard/components-next/sidebar/Sidebar.vue` | montagem | UX | Volta para o atendimento no topo da barra, dentro da central |
| `app/javascript/dashboard/components-next/sidebar/Sidebar.vue` | gancho | UX | Os itens da Central passam pelo organizador por seções |
| `app/javascript/dashboard/components-next/sidebar/Sidebar.vue` | gancho | SPEC-03 | Itens dentro de Conversas conforme a área de trabalho (2 linhas) |
| `app/javascript/dashboard/routes/dashboard/conversation/ContactPanel.vue` | gancho | SPEC-17 | Aplicativo ao lado da conversa como seção do painel direito (5 linhas) |
| `app/javascript/dashboard/App.vue` | gancho | SPEC-16 | Cartão de convite de atendimento no canto da tela (3 linhas) |
| `app/javascript/dashboard/routes/dashboard/conversation/Macros/List.vue` | gancho | SPEC-04 | `v-show` por macro conforme a área de trabalho |
| `app/javascript/dashboard/components-next/sidebar/SidebarProfileMenuStatus.vue` | gancho | SPEC-09 | Lista de status e troca de status pelo catálogo da conta (4 linhas) |
| `app/javascript/dashboard/routes/dashboard/settings/automation/constants.js` | gancho | SPEC-08 | Eventos de SLA na lista de eventos e nas condições por evento das automações |
| `app/models/macro.rb` | gancho | SPEC-15 | Macro aceita as ações da camada StayDesk (definir campo e status do ticket) |
| `app/javascript/dashboard/components/widgets/conversation/MoreActions.vue` | gancho | SPEC-10 | Seletor de status personalizado no lugar do botão Resolver quando a conta tem catálogo (3 linhas) |

## Views sobrepostas (o original não muda)

| Arquivo | Tipo | Spec | Motivo |
|---|---|---|---|
| `app/views/super_admin/devise/sessions/new.html.erb` | view | SPEC-02 | Título e `alt` do logo fixos no HTML |
| `app/views/super_admin/application/_navigation.html.erb` | view | SPEC-02 | `alt` do logo e texto de versão fixos |
| `app/views/installation/onboarding/index.html.erb` | view | SPEC-02 | Título, `alt` e boas-vindas da instalação |
| `app/views/mailers/administrator_notifications/account_compliance_mailer/account_deleted.liquid` | view | SPEC-02 | E-mail com o nome fixo |
| `app/views/mailers/administrator_notifications/account_notification_mailer/account_deletion_user_initiated.liquid` | view | SPEC-02 | E-mail com o nome fixo |
| `app/views/mailers/administrator_notifications/account_notification_mailer/account_deletion_for_inactivity.liquid` | view | SPEC-02 | E-mail com o nome fixo |

Ícones e manifesto em `public/` são substituídos no lugar (binários e JSON de marca); o gate os ignora.

## Legado do ramo de UX (a migrar)

Edições no lugar feitas antes desta regra, quase todas de classe. Cada arquivo sai desta lista quando
for reduzido a classe-só (passa a `classe`) ou quando a mudança for movida para a camada.

| Arquivo | Tipo | Spec | Motivo |
|---|---|---|---|
| `app/javascript/dashboard/components-next/Companies/CompaniesHeader/CompanyHeader.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/Companies/CompaniesListLayout.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/Companies/CompanyDetail/CompanyContactsSidebar.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/Companies/CompanyDetail/CompanyNotesSidebar.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/Contacts/ContactsCard/ContactsCard.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/Contacts/ContactsForm/ContactImportDialog.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/Contacts/ContactsHeader/ContactHeader.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/Contacts/ContactsListLayout.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/Contacts/ContactsSidebar/ContactMerge.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/Contacts/Pages/ContactsList.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/Conversation/ConversationCard/ConversationCardExpanded.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/Conversation/ConversationCard/UnreadBadge.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/Conversation/SidepanelSwitch.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/Inbox/InboxCard.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/button/Button.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/copilot/CopilotInput.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/input/ChoiceToggle.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/input/Input.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/message/Message.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/message/MessageList.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/message/bubbles/Base.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/message/bubbles/Text/Index.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/sidebar/Sidebar.vue` | legado | UX | Edição no lugar do ramo de UX; leva 4 linhas `staydesk:hook` da SPEC-03 (grupo de views e entrada em Configurações) e 4 da SPEC-04 (filtro do menu) |
| `app/javascript/dashboard/components-next/sidebar/SidebarCollapsedPopover.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/sidebar/SidebarGroup.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/sidebar/SidebarGroupHeader.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/sidebar/SidebarGroupLeaf.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/sidebar/SidebarSubGroup.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/sidebar/specs/ChannelLeaf.spec.js` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/sidebar/specs/SidebarCollapsedPopover.spec.js` | legado | UX | Arquivo novo do ramo de UX em pasta do upstream |
| `app/javascript/dashboard/components-next/sidebar/specs/SidebarGroup.spec.js` | legado | UX | Arquivo novo do ramo de UX em pasta do upstream |
| `app/javascript/dashboard/components-next/sidebar/specs/SidebarGroupHeader.spec.js` | legado | UX | Arquivo novo do ramo de UX em pasta do upstream |
| `app/javascript/dashboard/components-next/sidebar/specs/SidebarSubGroup.spec.js` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components-next/tabbar/TabBar.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components/Accordion/AccordionItem.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components/ChatList.vue` | legado | UX | Edição no lugar do ramo de UX; leva 4 linhas `staydesk:hook` da SPEC-03 (view por time como pasta ativa), 5 da SPEC-04 (lista em tabela) e 1 da SPEC-03 (abas da lista conforme a área de trabalho) |
| `app/javascript/dashboard/components/ChatListHeader.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components/ConversationList.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components/ui/Tabs/TabsItem.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components/widgets/ChatTypeTabs.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components/widgets/WootWriter/EditorModeToggle.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components/widgets/WootWriter/ReplyBottomPanel.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components/widgets/WootWriter/ReplyTopPanel.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components/widgets/conversation/CannedResponse.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components/widgets/conversation/ConversationBox.vue` | legado | UX | Edição no lugar do ramo de UX; leva 3 linhas `staydesk:hook` da SPEC-04 (Dashboard Apps) |
| `app/javascript/dashboard/components/widgets/conversation/ConversationCard.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components/widgets/conversation/ConversationHeader.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components/widgets/conversation/ConversationSidebar.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components/widgets/conversation/MessagesView.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components/widgets/conversation/ReplyBox.vue` | legado | UX | Edição no lugar do ramo de UX; leva 3 linhas `staydesk:hook` da SPEC-04 (Enviar como) |
| `app/javascript/dashboard/components/widgets/conversation/conversationBulkActions/BulkLabelActions.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/components/widgets/conversation/conversationBulkActions/Index.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/i18n/locale/en/chatlist.json` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/routes/dashboard/Dashboard.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/routes/dashboard/companies/pages/CompaniesIndex.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/routes/dashboard/conversation/ContactPanel.vue` | legado | UX | Edição no lugar do ramo de UX; leva 3 linhas `staydesk:hook` da SPEC-04 (seções por área de trabalho) |
| `app/javascript/dashboard/routes/dashboard/conversation/ConversationView.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/routes/dashboard/inbox/components/InboxDisplayMenu.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/routes/dashboard/inbox/components/MenuItem.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/routes/dashboard/inbox/helpers/InboxViewHelpers.js` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/routes/dashboard/settings/reports/ReportContainer.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/routes/dashboard/settings/reports/components/BotMetrics.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/routes/dashboard/settings/reports/components/CsatMetrics.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/routes/dashboard/settings/reports/components/CsatTable.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/routes/dashboard/settings/reports/components/ReportDrilldownCard.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/routes/dashboard/settings/reports/components/SLA/SLAMetrics.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/routes/dashboard/settings/reports/components/SLA/SLATable.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/routes/dashboard/settings/reports/components/SummaryReports.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/dashboard/routes/dashboard/settings/reports/components/overview/MetricCard.vue` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/shared/store/globalConfig.js` | legado | UX | Edição no lugar do ramo de UX |
| `app/javascript/shared/store/specs/globalConfig.spec.js` | legado | UX | Arquivo novo do ramo de UX em pasta do upstream |
