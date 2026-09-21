# Entra em ConversationReplyMailer pelo gancho prepend_mod_with.
#
# A resposta ao cliente saía sem layout nenhum: texto solto, sem marca, sem
# assinatura, e o pedido de avaliação virava um link cru no meio da frase. O
# layout com a identidade e a assinatura de quem respondeu é o que o Zendesk
# entrega hoje, e é o que o cliente espera de uma empresa.
module Custom::ConversationReplyMailer
  ACOES_PARA_O_CLIENTE = %w[email_reply reply_without_summary reply_with_summary].freeze

  private

  def choose_layout
    return 'mailer/staydesk' if action_name.in?(ACOES_PARA_O_CLIENTE)

    super
  end

  # O idioma da conta só é conhecido depois que a ação carrega a conversa, e a
  # troca de idioma do produto acontece antes disso: sem isto, a resposta ao
  # cliente de uma conta em português sai escrita em inglês.
  def prepare_mail(cc_bcc_enabled)
    staydesk_preparar_marca
    I18n.with_locale(@account&.locale.presence || I18n.locale) { super }
  end

  def staydesk_preparar_marca
    staydesk_preparar_assinatura
    @staydesk_marca = @account&.name.presence || @inbox&.sanitized_business_name
    @staydesk_endereco = staydesk_endereco_de_resposta
    @staydesk_logo = staydesk_logo_url
  end

  # Quem assina é quem respondeu; mensagem automática não ganha assinatura.
  def staydesk_preparar_assinatura
    agente = current_message&.sender || @agent
    return @staydesk_agente = nil unless agente.is_a?(User)

    @staydesk_agente = agente.available_name
    @staydesk_agente_avatar = agente.avatar_url.presence
  end

  # No rodapé vale o endereço para onde o cliente responde, sem o nome colado
  # que algumas configurações trazem ("StayDesk <suporte@...>").
  def staydesk_endereco_de_resposta
    bruto = @channel.try(:email).presence || @inbox&.email_address.presence || @account&.support_email
    bruto.to_s[/<([^>]+)>/, 1] || bruto
  end

  # A logo vai por URL absoluta: cliente de e-mail não carrega imagem do anexo
  # do produto nem enxerga caminho relativo.
  def staydesk_logo_url
    base = ENV.fetch('FRONTEND_URL', nil)
    return if base.blank?

    "#{base.chomp('/')}/brand-assets/logo-email.png"
  end
end
