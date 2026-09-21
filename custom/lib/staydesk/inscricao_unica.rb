# frozen_string_literal: true

# O produto reinscreve os ouvintes de evento a cada carga da aplicação, e o
# despachante é um singleton: o mesmo ouvinte terminava inscrito duas vezes (um
# objeto por carga) e cada evento rodava em dobro — o cliente recebia dois
# avisos de "recebemos o seu chamado" para o mesmo ticket. Aqui cada classe de
# ouvinte fica com uma inscrição só, sempre a mais recente.
module Staydesk::InscricaoUnica
  def load_listeners
    listeners.each { |listener| reinscrever(listener) }
  end

  private

  def reinscrever(listener)
    registros = local_registrations
    registros.delete_if { |registro| registro.listener.instance_of?(listener.class) }
    subscribe(listener)
  end
end
