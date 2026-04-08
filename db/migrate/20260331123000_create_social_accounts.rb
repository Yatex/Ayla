class CreateSocialAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :social_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :external_uid, null: false
      t.string :username
      t.text :access_token
      t.text :refresh_token
      t.datetime :expires_at
      t.boolean :active, null: false, default: true
      t.datetime :connected_at
      t.datetime :last_synced_at
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :social_accounts, [:user_id, :provider], unique: true
    add_index :social_accounts, [:provider, :external_uid], unique: true
  end
end
