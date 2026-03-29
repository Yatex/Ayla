class CreateTelegramConnections < ActiveRecord::Migration[7.1]
  def change
    create_table :telegram_connections do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.bigint :telegram_user_id, null: false
      t.bigint :telegram_chat_id, null: false
      t.string :username
      t.string :first_name
      t.string :last_name
      t.string :state, default: "idle", null: false
      t.boolean :active, default: true, null: false
      t.datetime :connected_at

      t.timestamps
    end

    add_index :telegram_connections, :telegram_user_id, unique: true
    add_index :telegram_connections, :telegram_chat_id
  end
end
