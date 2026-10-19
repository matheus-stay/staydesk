# Entra em AccountUser pelo gancho prepend_mod_with('AccountUser').
module Custom::AccountUser
  LIGHT_PERMISSION = 'staydesk_light'.freeze

  def self.prepended(base)
    base.has_one :staydesk_role, class_name: 'Staydesk::AccountUserRole', dependent: :destroy
  end

  def staydesk_light?
    staydesk_role&.kind == 'light'
  end

  # Permissões granulares do papel StayDesk (SPEC-12).
  def staydesk_permissions
    staydesk_role&.permissions || []
  end

  def staydesk_can?(permission)
    administrator? || staydesk_permissions.include?(permission.to_s)
  end

  # O front recebe isto no payload do usuário: é o que mostra ou esconde menu e rota.
  def permissions
    (super + staydesk_permissions).uniq
  end
end
