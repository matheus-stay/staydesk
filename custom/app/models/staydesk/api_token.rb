# Token de API com escopo próprio: quem integra escolhe o que o token lê e o que
# ele escreve, e não herda tudo que a pessoa pode. O valor só aparece na criação;
# o banco guarda o resumo, então token vazado não se lê de volta daqui.
#
# O token age em nome de um usuário da conta, então as permissões desse usuário
# continuam valendo: o escopo estreita, nunca amplia.
class Staydesk::ApiToken < ApplicationRecord
  self.table_name = 'staydesk_api_tokens'

  PREFIXO = 'sd'.freeze

  belongs_to :account
  belongs_to :user

  validates :name, presence: true
  validate :scopes_are_known

  scope :ativos, -> { where(active: true) }
  scope :ordered, -> { order(created_at: :desc) }

  attr_reader :token_em_claro

  # Cria e devolve o registro com o valor em claro disponível uma única vez.
  def self.gerar!(atributos)
    valor = "#{PREFIXO}_#{SecureRandom.hex(24)}"
    token = new(atributos.merge(token_digest: resumo(valor), token_hint: valor.last(4)))
    token.save!
    token.instance_variable_set(:@token_em_claro, valor)
    token
  end

  def self.resumo(valor)
    Digest::SHA256.hexdigest(valor.to_s)
  end

  # Encontra o token do cabeçalho, se ele existir, estiver ativo e não vencido.
  def self.autenticar(valor)
    return if valor.blank? || !valor.to_s.start_with?("#{PREFIXO}_")

    token = ativos.find_by(token_digest: resumo(valor))
    return if token.blank? || token.vencido?

    token
  end

  def vencido?
    expires_at.present? && expires_at < Time.current
  end

  # O pedido passa se o escopo dele estiver na lista do token.
  def autoriza?(controller_path, metodo)
    exigido = Staydesk::ApiScope.exigido(controller_path, metodo)
    return false if exigido.blank?

    scopes.include?(exigido)
  end

  # Carimbo de uso, no máximo uma vez por minuto: é métrica, não é dado de negócio.
  def registrar_uso!
    return if last_used_at.present? && last_used_at > 1.minute.ago

    # rubocop:disable Rails/SkipsModelValidations
    update_column(:last_used_at, Time.current)
    # rubocop:enable Rails/SkipsModelValidations
  end

  private

  def scopes_are_known
    desconhecidos = (scopes || []).reject { |escopo| Staydesk::ApiScope.conhece?(escopo) }
    errors.add(:scopes, "não conhece: #{desconhecidos.join(', ')}") if desconhecidos.any?
  end
end
