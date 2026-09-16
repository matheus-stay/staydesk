# frozen_string_literal: true

# O núcleo aponta a classe de auditoria para 'Enterprise::AuditLog' por string
# (config/initializers/audited.rb). Na edição community esse módulo não é
# carregado; devolvemos o padrão da gem para não sobrar referência solta.
Rails.application.config.after_initialize do
  Audited.config { |config| config.audit_class = 'Audited::Audit' }
end
