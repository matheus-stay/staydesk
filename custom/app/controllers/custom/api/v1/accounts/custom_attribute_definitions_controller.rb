# Entra no controller de atributos pelo gancho prepend_mod_with: o campo do
# ticket ganha a marcação de obrigatório para resolver, que é nossa.
module Custom::Api::V1::Accounts::CustomAttributeDefinitionsController
  private

  def permitted_payload
    params.require(:custom_attribute_definition).permit(
      :attribute_display_name,
      :attribute_description,
      :attribute_display_type,
      :attribute_key,
      :attribute_model,
      :regex_pattern,
      :regex_cue,
      :staydesk_required_to_resolve,
      attribute_values: []
    )
  end
end
