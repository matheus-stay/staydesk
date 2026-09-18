# Campos do ticket: os atributos de conversa da conta, com a marcação de quais
# precisam estar preenchidos para o agente resolver. Serve à tela, à API e ao MCP.
class Staydesk::TicketFieldService
  def initialize(account)
    @account = account
  end

  def definicoes
    @definicoes ||= @account.custom_attribute_definitions.where(attribute_model: :conversation_attribute)
                            .order(:id)
  end

  def obrigatorios
    definicoes.select(&:staydesk_required_to_resolve)
  end

  # O que falta preencher nesta conversa para ela poder ser resolvida.
  def faltando(conversation)
    valores = conversation.custom_attributes || {}
    obrigatorios.reject { |campo| preenchido?(valores[campo.attribute_key]) }
  end

  # Os campos com o valor de cada um nesta conversa, para quem lê pela API.
  def para_conversa(conversation)
    valores = conversation.custom_attributes || {}
    definicoes.map do |campo|
      {
        key: campo.attribute_key,
        label: campo.attribute_display_name,
        type: campo.attribute_display_type,
        values: campo.attribute_values,
        required_to_resolve: campo.staydesk_required_to_resolve,
        value: valores[campo.attribute_key],
        filled: preenchido?(valores[campo.attribute_key])
      }
    end
  end

  private

  def preenchido?(valor)
    return false if valor.nil?
    return valor.any? if valor.is_a?(Array)
    return true if [true, false].include?(valor)

    valor.to_s.strip.present?
  end
end
