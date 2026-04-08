# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_04_02_101000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "campaign_plans", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.date "start_on", null: false
    t.date "end_on", null: false
    t.string "status", default: "draft", null: false
    t.string "objective"
    t.text "message_angle"
    t.jsonb "focus_areas", default: [], null: false
    t.text "expected_outcomes"
    t.text "strategic_alignment"
    t.text "learnings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "start_on"], name: "index_campaign_plans_on_user_id_and_start_on"
    t.index ["user_id", "status"], name: "index_campaign_plans_on_user_id_and_status"
    t.index ["user_id"], name: "index_campaign_plans_on_user_id"
  end

  create_table "content_drafts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "conversation_id"
    t.text "body", null: false
    t.string "platform"
    t.string "status", default: "draft", null: false
    t.datetime "approved_at"
    t.datetime "rejected_at"
    t.datetime "posted_at"
    t.text "rejection_reason"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_content_drafts_on_conversation_id"
    t.index ["user_id", "created_at"], name: "index_content_drafts_on_user_id_and_created_at"
    t.index ["user_id", "status"], name: "index_content_drafts_on_user_id_and_status"
    t.index ["user_id"], name: "index_content_drafts_on_user_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "telegram_connection_id", null: false
    t.string "status", default: "active", null: false
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["telegram_connection_id"], name: "index_conversations_on_telegram_connection_id"
    t.index ["user_id", "status"], name: "index_conversations_on_user_id_and_status"
    t.index ["user_id"], name: "index_conversations_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.string "role", null: false
    t.text "content", null: false
    t.bigint "telegram_message_id"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
  end

  create_table "social_accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider", null: false
    t.string "external_uid", null: false
    t.string "username"
    t.text "access_token"
    t.text "refresh_token"
    t.datetime "expires_at"
    t.boolean "active", default: true, null: false
    t.datetime "connected_at"
    t.datetime "last_synced_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "external_uid"], name: "index_social_accounts_on_provider_and_external_uid", unique: true
    t.index ["user_id", "provider"], name: "index_social_accounts_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_social_accounts_on_user_id"
  end

  create_table "telegram_connections", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "telegram_user_id", null: false
    t.bigint "telegram_chat_id", null: false
    t.string "username"
    t.string "first_name"
    t.string "last_name"
    t.string "state", default: "idle", null: false
    t.boolean "active", default: true, null: false
    t.datetime "connected_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["telegram_chat_id"], name: "index_telegram_connections_on_telegram_chat_id"
    t.index ["telegram_user_id"], name: "index_telegram_connections_on_telegram_user_id", unique: true
    t.index ["user_id"], name: "index_telegram_connections_on_user_id", unique: true
  end

  create_table "user_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "tone", default: "professional"
    t.string "posting_frequency", default: "daily"
    t.jsonb "preferred_platforms", default: []
    t.jsonb "content_types", default: []
    t.jsonb "active_hours", default: {}
    t.text "custom_instructions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "assistant_channel", default: "telegram", null: false
    t.string "whatsapp_number"
    t.index ["user_id"], name: "index_user_preferences_on_user_id", unique: true
  end

  create_table "user_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "bio"
    t.string "timezone", default: "UTC"
    t.string "language", default: "en"
    t.string "onboarding_step", default: "pending"
    t.datetime "onboarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "brand_summary"
    t.text "positioning"
    t.text "target_audience"
    t.text "strategic_objectives"
    t.text "main_offers"
    t.text "strategic_notes"
    t.index ["user_id"], name: "index_user_profiles_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "telegram_link_token"
    t.datetime "telegram_link_token_generated_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["telegram_link_token"], name: "index_users_on_telegram_link_token", unique: true
  end

  add_foreign_key "campaign_plans", "users"
  add_foreign_key "content_drafts", "conversations"
  add_foreign_key "content_drafts", "users"
  add_foreign_key "conversations", "telegram_connections"
  add_foreign_key "conversations", "users"
  add_foreign_key "messages", "conversations"
  add_foreign_key "social_accounts", "users"
  add_foreign_key "telegram_connections", "users"
  add_foreign_key "user_preferences", "users"
  add_foreign_key "user_profiles", "users"
end
