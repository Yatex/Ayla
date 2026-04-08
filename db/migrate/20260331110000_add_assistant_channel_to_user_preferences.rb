class AddAssistantChannelToUserPreferences < ActiveRecord::Migration[7.1]
  def change
    add_column :user_preferences, :assistant_channel, :string, default: "telegram", null: false
  end
end
