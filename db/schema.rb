# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100125202550) do

  create_table "configuration_categories", :force => true do |t|
    t.string   "description"
    t.string   "predictable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "configuration_contests", :force => true do |t|
    t.string   "name"
    t.datetime "available_from"
    t.datetime "available_to"
    t.datetime "participation_ends_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "configuration_included_objectives", :force => true do |t|
    t.integer  "configuration_set_id"
    t.integer  "configuration_objective_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "configuration_included_sets", :force => true do |t|
    t.integer  "configuration_set_id"
    t.integer  "configuration_contest_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "configuration_objectives", :force => true do |t|
    t.integer  "configuration_category_id"
    t.string   "description"
    t.string   "predictable_field"
    t.string   "predictable_field_type"
    t.integer  "possible_points"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "configuration_predictable_items", :force => true do |t|
    t.integer  "configuration_set_id"
    t.integer  "predictable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "configuration_sets", :force => true do |t|
    t.string   "description"
    t.boolean  "mutex_objectives"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "core_predictions", :force => true do |t|
    t.integer  "core_user_id"
    t.integer  "configuration_predictable_item_id"
    t.string   "predicted_value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "core_predictions", ["configuration_predictable_item_id"], :name => "index_core_predictions_on_configuration_predictable_item_id"
  add_index "core_predictions", ["core_user_id"], :name => "index_core_predictions_on_core_user_id"

  create_table "core_users", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",                            :null => false
    t.string   "name",                             :null => false
    t.string   "crypted_password",                 :null => false
    t.string   "password_salt",                    :null => false
    t.string   "persistence_token",                :null => false
    t.integer  "login_count",       :default => 0, :null => false
    t.datetime "last_request_at"
    t.datetime "last_login_at"
    t.datetime "current_login_at"
    t.string   "last_login_ip"
    t.string   "current_login_ip"
  end

  add_index "core_users", ["email"], :name => "index_core_users_on_email"
  add_index "core_users", ["last_request_at"], :name => "index_core_users_on_last_request_at"
  add_index "core_users", ["persistence_token"], :name => "index_core_users_on_persistence_token"

  create_table "predictable_championship_group_table_positions", :force => true do |t|
    t.integer  "pos"
    t.integer  "predictable_championship_group_id"
    t.integer  "predictable_championship_team_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "predictable_championship_groups", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "predictable_championship_matches", :force => true do |t|
    t.string   "description"
    t.string   "score"
    t.string   "result"
    t.datetime "play_date"
    t.integer  "home_team_id"
    t.integer  "away_team_id"
    t.integer  "predictable_championship_stage_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "predictable_championship_players", :force => true do |t|
    t.string   "name"
    t.integer  "predictable_championship_team_id"
    t.integer  "goals",                            :default => 0
    t.boolean  "selectable",                       :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "predictable_championship_stage_teams", :force => true do |t|
    t.integer  "predictable_championship_stage_id"
    t.integer  "predictable_championship_team_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "predictable_championship_stages", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "predictable_championship_teams", :force => true do |t|
    t.string   "code"
    t.string   "name"
    t.string   "country_flag"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "prediction_summaries", :force => true do |t|
    t.string   "state"
    t.integer  "map",                  :default => 650
    t.integer  "core_user_id",                          :null => false
    t.integer  "total_score",          :default => 0
    t.integer  "previous_score",       :default => 0
    t.integer  "previous_map",         :default => 0
    t.integer  "percentage_completed", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "prediction_summaries", ["core_user_id"], :name => "index_prediction_summaries_on_core_user_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

end
