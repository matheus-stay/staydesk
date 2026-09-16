# frozen_string_literal: true

# O título do super admin vem do helper application_title da gem Administrate,
# que usa o nome do módulo Rails ("Chatwoot"). Não há InstallationConfig para isso.
Rails.application.config.to_prepare do
  Administrate::ApplicationHelper.module_eval do
    def application_title
      'StayDesk'
    end
  end
end
