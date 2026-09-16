# Entra em AccountUser pelo gancho prepend_mod_with('AccountUser').
module Custom::AccountUser
  LIGHT_PERMISSION = 'staydesk_light'.freeze

  def self.prepended(base)
    base.has_one :staydesk_role, class_name: 'Staydesk::AccountUserRole', dependent: :destroy
  end

  def staydesk_light?
    staydesk_role&.kind == 'light'
  end

  # O front recebe isto no payload do usuário e esconde o que o leve não pode fazer.
  def permissions
    staydesk_light? ? super + [LIGHT_PERMISSION] : super
  end
end
