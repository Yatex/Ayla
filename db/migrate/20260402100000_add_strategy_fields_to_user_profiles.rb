class AddStrategyFieldsToUserProfiles < ActiveRecord::Migration[7.1]
  def change
    add_column :user_profiles, :brand_summary, :text
    add_column :user_profiles, :positioning, :text
    add_column :user_profiles, :target_audience, :text
    add_column :user_profiles, :strategic_objectives, :text
    add_column :user_profiles, :main_offers, :text
    add_column :user_profiles, :strategic_notes, :text
  end
end
