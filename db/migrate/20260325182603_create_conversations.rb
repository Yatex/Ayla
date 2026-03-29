class CreateConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :conversations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :telegram_connection, null: false, foreign_key: true
      t.string :status, default: "active", null: false
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end

    add_index :conversations, [:user_id, :status]
  end
end
