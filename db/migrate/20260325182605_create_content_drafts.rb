class CreateContentDrafts < ActiveRecord::Migration[7.1]
  def change
    create_table :content_drafts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :conversation, foreign_key: true
      t.text :body, null: false
      t.string :platform
      t.string :status, default: "draft", null: false
      t.datetime :approved_at
      t.datetime :rejected_at
      t.datetime :posted_at
      t.text :rejection_reason
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :content_drafts, [:user_id, :status]
    add_index :content_drafts, [:user_id, :created_at]
  end
end
