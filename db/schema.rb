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

ActiveRecord::Schema[8.1].define(version: 2026_09_08_161521) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "collection_epics", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.datetime "created_at", null: false
    t.bigint "epic_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "epic_id"], name: "index_collection_epics_on_collection_id_and_epic_id", unique: true
    t.index ["collection_id"], name: "index_collection_epics_on_collection_id"
    t.index ["epic_id"], name: "index_collection_epics_on_epic_id"
  end

  create_table "collections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "visibility", default: 0, null: false
    t.index ["user_id"], name: "index_collections_on_user_id"
  end

  create_table "epics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "end_time", null: false
    t.integer "start_time", null: false
    t.string "title", null: false
    t.bigint "track_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "visibility", default: 0, null: false
    t.index ["track_id"], name: "index_epics_on_track_id"
    t.index ["user_id", "track_id"], name: "index_epics_on_user_id_and_track_id", unique: true
    t.index ["user_id"], name: "index_epics_on_user_id"
    t.check_constraint "end_time > start_time", name: "epics_end_time_greater_than_start"
    t.check_constraint "start_time >= 0", name: "epics_start_time_non_negative"
  end

  create_table "picks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "epic_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["epic_id"], name: "index_picks_on_epic_id"
    t.index ["user_id", "epic_id"], name: "index_picks_on_user_id_and_epic_id", unique: true
    t.index ["user_id"], name: "index_picks_on_user_id"
  end

  create_table "spotify_accounts", force: :cascade do |t|
    t.text "access_token"
    t.datetime "created_at", null: false
    t.string "email"
    t.datetime "expires_at"
    t.string "product"
    t.text "refresh_token"
    t.string "spotify_uid", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["spotify_uid"], name: "index_spotify_accounts_on_spotify_uid", unique: true
    t.index ["user_id"], name: "index_spotify_accounts_on_user_id", unique: true
  end

  create_table "tracks", force: :cascade do |t|
    t.string "album_artwork_url"
    t.string "album_name"
    t.string "artist_name", null: false
    t.datetime "created_at", null: false
    t.integer "duration_ms", null: false
    t.string "name", null: false
    t.string "spotify_id", null: false
    t.datetime "updated_at", null: false
    t.index ["spotify_id"], name: "index_tracks_on_spotify_id", unique: true
    t.check_constraint "duration_ms > 0", name: "tracks_duration_positive"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "display_name"
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.integer "visibility", default: 0, null: false
    t.index "lower((username)::text)", name: "index_users_on_lower_username", unique: true
  end

  add_foreign_key "collection_epics", "collections", on_delete: :cascade
  add_foreign_key "collection_epics", "epics", on_delete: :cascade
  add_foreign_key "collections", "users", on_delete: :cascade
  add_foreign_key "epics", "tracks", on_delete: :cascade
  add_foreign_key "epics", "users", on_delete: :cascade
  add_foreign_key "picks", "epics", on_delete: :cascade
  add_foreign_key "picks", "users", on_delete: :cascade
  add_foreign_key "spotify_accounts", "users"
end
