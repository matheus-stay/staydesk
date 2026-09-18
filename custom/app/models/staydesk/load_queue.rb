# Filas de carga (SPEC-11): quantas conversas simultâneas o agente aguenta é
# contado por fila, e é a caixa que diz de qual fila a conversa é. O mapa de
# canal para fila é da operação, não do produto: quem trata WhatsApp como ticket,
# ou abre chamado por API, configura aqui em vez de depender de código.
class Staydesk::LoadQueue < ApplicationRecord
  self.table_name = 'staydesk_load_queues'

  # Só vale enquanto a conta não define as suas: chat pega tudo, e-mail é ticket.
  DEFAULTS = [
    { key: 'chat', name: 'Chat', channel_types: [], inbox_ids: [], catch_all: true, position: 0 },
    { key: 'ticket', name: 'Ticket', channel_types: ['Channel::Email'], inbox_ids: [], catch_all: false, position: 1 }
  ].freeze

  belongs_to :account

  validates :key, presence: true, uniqueness: { scope: :account_id }
  validates :name, presence: true

  scope :ordered, -> { order(:position, :id) }

  # As filas da conta; sem nenhuma configurada, o padrão do produto.
  def self.resolved(account)
    salvas = where(account_id: account.id).ordered.to_a
    return salvas if salvas.any?

    DEFAULTS.map { |dados| new(dados.merge(account_id: account.id)) }
  end

  def self.keys_for(account)
    resolved(account).map(&:key)
  end

  # Qual fila atende esta caixa: a que lista a caixa pelo nome vale mais que a que
  # lista o canal, porque um mesmo tipo de canal serve a coisas diferentes (a API
  # atende tanto WhatsApp quanto chamado aberto por integração). Sobrou, é da coringa.
  def self.for_inbox(inbox)
    filas = resolved(inbox.account)
    filas.find { |fila| fila.inbox_ids.include?(inbox.id) } ||
      filas.find { |fila| fila.channel_types.include?(inbox.channel_type) } ||
      coringa(filas)
  end

  def self.coringa(filas)
    filas.find(&:catch_all) || filas.first
  end

  # Canais e caixas reivindicados por outras filas: o que sobra é da coringa.
  def self.claimed_channel_types(account)
    resolved(account).reject(&:catch_all).flat_map(&:channel_types).uniq
  end

  def self.claimed_inbox_ids(account)
    resolved(account).reject(&:catch_all).flat_map(&:inbox_ids).uniq
  end
end
