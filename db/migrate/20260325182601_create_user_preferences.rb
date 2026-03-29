class CreateUserPreferences < ActiveRecord::Migration[7.1]
  def change
    create_table :user_preferences do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :tone, default: "professional"
      t.string :posting_frequency, default: "daily"
      t.jsonb :preferred_platforms, default: []
      t.jsonb :content_types, default: []
      t.jsonb :active_hours, default: {}
      t.text :custom_instructions

      t.timestamps
    end
  end
end
