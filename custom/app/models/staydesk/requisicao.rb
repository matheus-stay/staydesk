# Memória de uma requisição (ou de um job): o Rails zera ao terminar. Serve para
# catálogos da conta lidos muitas vezes no mesmo pedido, como o bloco `staydesk`
# de cada conversa de uma lista.
class Staydesk::Requisicao < ActiveSupport::CurrentAttributes
  attribute :guardado

  def self.guardar(chave)
    self.guardado ||= {}
    guardado.fetch(chave) { guardado[chave] = yield }
  end
end
