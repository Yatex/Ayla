class CreateCampaignPlans < ActiveRecord::Migration[7.1]
  def change
    create_table :campaign_plans do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.date :start_on, null: false
      t.date :end_on, null: false
      t.string :status, null: false, default: "draft"
      t.string :objective
      t.text :message_angle
      t.jsonb :focus_areas, null: false, default: []
      t.text :expected_outcomes
      t.text :strategic_alignment
      t.text :learnings

      t.timestamps
    end

    add_index :campaign_plans, [:user_id, :status]
    add_index :campaign_plans, [:user_id, :start_on]
  end
end
