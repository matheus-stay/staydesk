# Quanto a pesquisa de satisfação espera antes de sair, por canal. Fica no
# `csat_config` do canal, junto do resto da configuração de pesquisa do produto.
module Staydesk::Csat
  CHAVE = 'staydesk_atraso_em_minutos'.freeze
  PADRAO_EM_MINUTOS = 5

  module_function

  def atraso(inbox)
    minutos = inbox&.csat_config.is_a?(Hash) ? inbox.csat_config[CHAVE] : nil
    minutos = PADRAO_EM_MINUTOS if minutos.blank?
    [minutos.to_i, 0].max.minutes
  end
end
