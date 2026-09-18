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
