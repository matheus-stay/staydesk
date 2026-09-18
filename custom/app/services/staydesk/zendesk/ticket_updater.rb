# Aplica na conversa o que o dashboard manda no formato do Zendesk (escalação:
# status, responsável, grupo, tags, campos e um comentário público ou interno).
class Staydesk::Zendesk::TicketUpdater
  STATUS = Staydesk::Zendesk::Serializer::STATUS_DO_ZENDESK
  PRIORIDADE = { 'low' => 'low', 'normal' => 'medium', 'high' => 'high', 'urgent' => 'urgent' }.freeze

  def initialize(account, conversation)
    @account = account
    @conversation = conversation
  end

  def perform(dados)
    atributos = atributos_de(dados)
    @conversation.update!(atributos) if atributos.any?
    @conversation.update_labels(Array(dados['tags'])) if dados.key?('tags')
    comentar(dados['comment']) if dados.dig('comment', 'body').present?
    @conversation
  end

  private

  def atributos_de(dados)
    atributos = {}
    atributos[:status] = STATUS.fetch(dados['status'], dados['status']) if dados['status'].present?
    atributos[:priority] = PRIORIDADE[dados['priority']] if dados.key?('priority')
    atributos[:assignee_id] = dados['assignee_id'] if dados.key?('assignee_id')
    atributos[:team_id] = dados['group_id'] if dados.key?('group_id')
    atributos[:custom_attributes] = campos(dados['custom_fields'], dados['subject']) if dados['custom_fields'].present? || dados['subject'].present?
    atributos
  end

  def campos(lista, assunto)
    definicoes = @account.custom_attribute_definitions.where(attribute_model: 'conversation_attribute').index_by(&:id)
    novos = @conversation.custom_attributes.dup
    Array(lista).each do |campo|
      definicao = definicoes[campo['id'].to_i]
      novos[definicao.attribute_key] = campo['value'] if definicao
    end
    novos['assunto'] = assunto if assunto.present?
    novos
  end

  # Comentário público vira resposta ao cliente; privado vira nota interna.
  def comentar(comentario)
    publico = ActiveModel::Type::Boolean.new.cast(comentario['public'])
    publico = true if publico.nil?
    @conversation.messages.create!(
      account: @account, inbox: @conversation.inbox, message_type: :outgoing,
      content: comentario['body'], private: !publico, sender: Current.user
    )
  end
end
