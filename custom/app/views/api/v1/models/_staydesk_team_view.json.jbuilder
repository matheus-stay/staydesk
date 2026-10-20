json.id resource.id
json.name resource.name
json.description resource.description
json.color resource.color
json.icon resource.icon
json.query resource.query
# A consulta pronta para o filtro de conversas do produto: canal de trabalho já
# virou caixas e `me` virou quem pede. A lista na tela usa esta; `query` é a que
# se edita.
json.resolved_query({ payload: resource.payload(Current.user) })
json.columns resource.columns
json.sort_by resource.sort_by
json.position resource.position
json.team_ids resource.team_ids
json.created_by_id resource.created_by_id
json.created_at resource.created_at
json.updated_at resource.updated_at
