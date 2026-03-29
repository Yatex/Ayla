class CreateUserProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :user_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :bio
      t.string :timezone, default: "UTC"
      t.string :language, default: "en"
      t.string :onboarding_step, default: "pending"
      t.datetime :onboarded_at

      t.timestamps
    end
  end
end
