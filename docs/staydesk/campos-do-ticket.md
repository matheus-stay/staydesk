# Campos do ticket

Campo do ticket é atributo personalizado de conversa: o que a operação precisa
saber de cada caso além do texto. Tipo de demanda, produto, servidor, id do
cliente no WHMCS, classificação.

Ficam em Central › Regras e automação › Atributos personalizados, escolhendo o
modelo "conversa". Aceitam texto, número, moeda, percentual, link, data, lista e
caixa de seleção; a lista guarda as opções que o agente vê.

## Obrigatório para resolver

Cada campo de conversa pode ser marcado como **obrigatório para resolver**. Com a
marcação ligada, o agente não fecha a conversa enquanto o campo estiver vazio: a
tentativa volta com `422` e a mensagem diz quais campos faltam.

A regra vale para **quem atende**. Automação, robô e resolução automática por
inatividade não travam, senão a conversa ficaria presa sem ninguém para
preencher. É o mesmo desenho do Zendesk.

O que conta como preenchido: texto com qualquer caractere que não seja espaço,
número, data, link, lista com pelo menos uma opção escolhida, e caixa de seleção
marcada **ou** desmarcada, porque desmarcada também é resposta.

No painel do agente, campo obrigatório aparece com asterisco, e um aviso no topo
lista o que falta antes de ele tentar resolver.

Ao resolver com campo obrigatório vazio (botão Resolver, seletor de status, menu
da conversa ou "Enviar como" resolvido), abre a janela do produto que pede os
campos que faltam; preenchidos, a resolução segue. Os campos do StayDesk entram
nessa janela por um gancho em `useConversationRequiredAttributes.js`
(`staydesk/helpers/camposObrigatorios.js`). Se ainda assim o servidor recusar,
o aviso mostra a mensagem dele, que lista os campos.

No arquivo de configuração: `obrigatorio_para_resolver: true` na seção
`atributos` (ver [api-e-mcp.md](api-e-mcp.md)). Sem a chave, fica o que está
marcado na tela.

## O assunto do ticket

O assunto não é um campo do ticket, mas mora em dois lugares, e vale saber
quais. O ticket de e-mail grava em `additional_attributes.mail_subject`; o que
chega pela API (WHMCS) grava em `custom_attributes.assunto`. Ao salvar,
`Custom::Conversation#staydesk_assunto_unico` copia o `assunto` para
`mail_subject` quando este está vazio, para uma regra por assunto (gatilho,
fila) valer para os dois.

Onde o assunto aparece (tabela do Hub, home do Hub e API do Zendesk), a regra é
a do Zendesk: ticket de e-mail ou API mostra `mail_subject`, depois `assunto`,
depois "sem assunto"; chat e WhatsApp mostram "Chat com <cliente>", nunca a
última mensagem. No front, `app/javascript/staydesk/helpers/assunto.js`; na API
do Zendesk, `Staydesk::Zendesk::Serializer#assunto`.

## Pela API

| Endpoint | O que faz |
|---|---|
| `GET custom_attribute_definitions?attribute_model=conversation_attribute` | Catálogo de campos, com `staydesk_required_to_resolve` |
| `POST custom_attribute_definitions` | Cria um campo. Aceita `staydesk_required_to_resolve` |
| `PATCH custom_attribute_definitions/:id` | Altera, inclusive marcar ou desmarcar a obrigatoriedade |
| `GET staydesk/ticket_fields` | O mesmo catálogo, já filtrado em campos de conversa |
| `GET staydesk/conversations/:numero/ticket_fields` | Os campos **com o valor** naquela conversa e a lista do que falta para resolver |
| `PATCH staydesk/conversations/:numero/ticket_fields` | Preenche os campos informados, deixando os demais como estão |

Criar um campo de lista:

```sh
curl -X POST -H "api_access_token: $TOKEN" -H 'content-type: application/json' \
  -d '{"custom_attribute_definition":{
        "attribute_display_name":"Tipo de Demanda",
        "attribute_key":"tipo_de_demanda",
        "attribute_model":"conversation_attribute",
        "attribute_display_type":"list",
        "attribute_values":["Suporte","Dúvida","Incidente"],
        "staydesk_required_to_resolve":true}}' \
  "$URL/api/v1/accounts/1/custom_attribute_definitions"
```

Ler e preencher numa conversa:

```sh
curl -H "api_access_token: $TOKEN" \
  "$URL/api/v1/accounts/1/staydesk/conversations/423/ticket_fields"

curl -X PATCH -H "api_access_token: $TOKEN" -H 'content-type: application/json' \
  -d '{"custom_attributes":{"tipo_de_demanda":"Suporte"}}' \
  "$URL/api/v1/accounts/1/staydesk/conversations/423/ticket_fields"
```

A resposta de leitura e de preenchimento traz, para cada campo, a chave, o
rótulo, o tipo, as opções, se é obrigatório, o valor e se está preenchido, mais
`missing_to_resolve` com o que ainda falta.

## Pelo MCP

`staydesk_campos_do_ticket_listar`, `staydesk_campos_do_ticket_criar`,
`staydesk_campos_do_ticket_atualizar`, `staydesk_campos_da_conversa` e
`staydesk_campos_da_conversa_preencher`. Ver [api-e-mcp.md](api-e-mcp.md).
