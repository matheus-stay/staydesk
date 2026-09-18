# Quem configura uma área do StayDesk: o administrador, quem tem a permissão
# geral de configurar, ou quem tem a permissão daquela área. É o que faz o papel
# granular (SPEC-12) valer no servidor, e não só esconder botão na tela.
module Staydesk::AreaDeConfiguracao
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def configura_a_area(area)
      define_method(:area_de_configuracao) { area.to_s }
    end
  end

  def configura?
    return true if @account_user.administrator?

    Staydesk::Role.permissions_for_area(area_de_configuracao).any? do |permissao|
      @account_user.staydesk_permissions.include?(permissao)
    end
  end

  def area_de_configuracao
    'configuracoes'
  end
end
