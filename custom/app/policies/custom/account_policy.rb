# Entra em AccountPolicy pelo gancho prepend_mod_with: um papel pode conceder a
# edição das configurações da conta sem tornar a pessoa administradora (SPEC-12).
module Custom::AccountPolicy
  def update?
    super || @account_user.staydesk_permissions.include?('staydesk_settings_manage')
  end

  def show?
    super || @account_user.staydesk_permissions.include?('staydesk_settings_manage')
  end
end
