class AddStaydeskRequiredToResolveToCustomAttributeDefinitions < ActiveRecord::Migration[7.1]
  def change
    add_column :custom_attribute_definitions, :staydesk_required_to_resolve, :boolean, default: false, null: false
  end
end
