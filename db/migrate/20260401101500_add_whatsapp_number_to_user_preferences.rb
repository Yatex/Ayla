class AddWhatsappNumberToUserPreferences < ActiveRecord::Migration[7.1]
  def change
    add_column :user_preferences, :whatsapp_number, :string
  end
end
