class AddTelegramLinkTokenToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :telegram_link_token, :string
    add_column :users, :telegram_link_token_generated_at, :datetime

    add_index :users, :telegram_link_token, unique: true
  end
end
