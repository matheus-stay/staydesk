# Os dados que o cliente quer ver no aviso de recebimento: o número que ele vai
# citar, o assunto que ele escreveu, por onde entrou e quando.
module Staydesk::EmailHelper
  def staydesk_dados_do_chamado(conversa, canal)
    {
      t('staydesk.email.recebimento.numero') => "##{conversa.display_id}",
      t('staydesk.email.recebimento.assunto') => staydesk_assunto_do_chamado(conversa),
      t('staydesk.email.recebimento.canal') => canal&.name,
      t('staydesk.email.recebimento.aberto_em') => I18n.l(conversa.created_at.in_time_zone(Time.zone), format: '%d/%m/%Y %H:%M')
    }.compact_blank
  end

  def staydesk_assunto_do_chamado(conversa)
    conversa.additional_attributes.to_h['mail_subject'].presence ||
      conversa.messages.incoming.first&.content.to_s.truncate(80).presence
  end
end
