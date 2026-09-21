# frozen_string_literal: true

# Os ativos da marca usados fora do produto, principalmente no e-mail. A URL da
# logo leva a impressão digital do arquivo: cliente de e-mail guarda a imagem
# pela URL (o Gmail serve por um proxy próprio), e sem isso uma logo trocada
# continua chegando velha por dias.
module Staydesk::Marca
  LOGO_DE_EMAIL = 'brand-assets/logo-email.png'

  module_function

  def logo_de_email(base_url)
    return if base_url.blank?

    "#{base_url.to_s.chomp('/')}/#{LOGO_DE_EMAIL}?v=#{versao_da_logo}"
  end

  def versao_da_logo
    @versao_da_logo ||= begin
      caminho = Rails.public_path.join(LOGO_DE_EMAIL)
      caminho.exist? ? Digest::MD5.file(caminho).hexdigest[0, 10] : '0'
    end
  end

  # O painel onde o cliente acompanha os chamados dele, quando a conta tem um.
  def painel_do_cliente(account)
    account&.custom_attributes.to_h['staydesk_painel_do_cliente'].presence
  end
end
