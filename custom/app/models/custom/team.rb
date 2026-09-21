# Entra em Team pelo gancho prepend_mod_with('Team').
#
# O produto grava o nome do grupo em minúsculas. No Zendesk o grupo aparece como
# foi escrito ("Suporte N1"), e é esse nome que a operação lê o dia inteiro na
# barra, nas visualizações e nos relatórios. Aqui o nome digitado é guardado e
# devolvido depois que o produto o normaliza; a unicidade passa a ignorar
# maiúsculas, que era o motivo de o produto ter derrubado tudo para minúsculas.
module Custom::Team
  def self.prepended(base)
    base.validates :name, uniqueness: { scope: :account_id, case_sensitive: false }
    # Registrado depois do gancho do produto, então roda depois dele.
    base.before_validation :staydesk_restaurar_o_nome_digitado
  end

  def name=(valor)
    # Dentro da validação quem escreve é o produto, passando o nome para
    # minúsculas: isso não é o nome digitado e não substitui o que guardamos.
    @staydesk_nome_digitado = staydesk_limpar(valor) unless @staydesk_em_validacao
    super
  end

  def run_validations!
    @staydesk_em_validacao = true
    super
  ensure
    @staydesk_em_validacao = false
  end

  private

  def staydesk_limpar(valor)
    valor.is_a?(String) ? valor.gsub(/[[:cntrl:]]/, '').strip : valor
  end

  def staydesk_restaurar_o_nome_digitado
    digitado = @staydesk_nome_digitado
    return unless digitado.is_a?(String) && digitado.present?
    return unless digitado.casecmp?(name.to_s)

    self[:name] = digitado
  end
end
