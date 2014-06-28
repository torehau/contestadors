# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140625222536) do

  create_table "comments", :force => true do |t|
    t.integer  "commentable_id",   :default => 0
    t.string   "commentable_type"
    t.string   "title"
    t.text     "body"
    t.string   "subject"
    t.integer  "user_id",          :default => 0, :null => false
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "removed"
    t.boolean  "blocked"
  end

  add_index "comments", ["commentable_id", "commentable_type"], :name => "index_comments_on_commentable_id_and_commentable_type"
  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"

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
    t.string   "predictable_module"
    t.string   "permalink"
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
    t.string   "state",                :default => "unsettled"
  end

  create_table "configuration_prediction_states", :force => true do |t|
    t.integer  "configuration_contest_id"
    t.string   "state_name"
    t.string   "permalink"
    t.string   "next_state_name"
    t.integer  "progress_delta"
    t.integer  "progress_accumulated"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "aggregate_root_type"
    t.integer  "aggregate_root_id"
    t.integer  "points_delta"
    t.integer  "points_accumulated"
    t.boolean  "preview_available",        :default => false
    t.integer  "position"
  end

  create_table "configuration_sets", :force => true do |t|
    t.string   "description"
    t.boolean  "mutex_objectives"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "configuration_prediction_state_id"
  end

  create_table "contest_instances", :force => true do |t|
    t.string   "name",                     :limit => 50, :null => false
    t.string   "permalink",                              :null => false
    t.integer  "configuration_contest_id",               :null => false
    t.integer  "admin_user_id",                          :null => false
    t.string   "uuid",                                   :null => false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "allow_join_by_url"
  end

  add_index "contest_instances", ["admin_user_id"], :name => "index_contest_instances_on_admin_user_id"
  add_index "contest_instances", ["permalink"], :name => "index_contest_instances_on_permalink"
  add_index "contest_instances", ["uuid"], :name => "index_contest_instances_on_uuid"

  create_table "high_score_list_positions", :force => true do |t|
    t.integer  "prediction_summary_id"
    t.integer  "user_id"
    t.integer  "configuration_contest_id"
    t.integer  "position"
    t.integer  "previous_position"
    t.boolean  "has_predictions"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "invitations", :force => true do |t|
    t.string   "name",                :null => false
    t.string   "email",               :null => false
    t.integer  "contest_instance_id", :null => false
    t.integer  "sender_id",           :null => false
    t.integer  "existing_user_id"
    t.string   "state"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "token"
  end

  add_index "invitations", ["contest_instance_id"], :name => "index_invitations_on_contest_instance_id"
  add_index "invitations", ["email"], :name => "index_invitations_on_email"
  add_index "invitations", ["existing_user_id"], :name => "index_invitations_on_existing_user_id"
  add_index "invitations", ["token"], :name => "index_invitations_on_token"

  create_table "operation_settings", :force => true do |t|
    t.boolean  "is_under_maintenance"
    t.string   "admin_user"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "participations", :force => true do |t|
    t.integer  "contest_instance_id", :null => false
    t.integer  "user_id",             :null => false
    t.integer  "invitation_id"
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "participations", ["contest_instance_id"], :name => "index_participations_on_contest_instance_id"
  add_index "participations", ["user_id"], :name => "index_participations_on_user_id"

  create_table "predictable_championship_group_qualifications", :force => true do |t|
    t.integer  "predictable_championship_group_id"
    t.integer  "group_pos"
    t.integer  "predictable_championship_match_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

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
    t.integer  "display_order"
  end

  create_table "predictable_championship_players", :force => true do |t|
    t.string   "name"
    t.integer  "predictable_championship_team_id"
    t.integer  "goals",                            :default => 0
    t.boolean  "selectable",                       :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "predictable_championship_stage_qualifications", :force => true do |t|
    t.integer  "predictable_championship_match_id"
    t.integer  "predictable_championship_stage_team_id"
    t.boolean  "is_winner"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "predictable_championship_stage_teams", :force => true do |t|
    t.integer  "predictable_championship_stage_id"
    t.integer  "predictable_championship_team_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "predictable_championship_match_id"
    t.boolean  "is_home_team"
  end

  create_table "predictable_championship_stages", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "next_stage_id"
  end

  create_table "predictable_championship_teams", :force => true do |t|
    t.string   "code"
    t.string   "name"
    t.string   "country_flag"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ranking_coefficient"
    t.integer  "tournament_id"
  end

  create_table "prediction_summaries", :force => true do |t|
    t.string   "state"
    t.integer  "map",                      :default => 500
    t.integer  "user_id",                                   :null => false
    t.integer  "total_score",              :default => 0
    t.integer  "previous_score",           :default => 0
    t.integer  "previous_map",             :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "configuration_contest_id"
  end

  add_index "prediction_summaries", ["user_id"], :name => "index_prediction_summaries_on_user_id"

  create_table "predictions", :force => true do |t|
    t.integer  "user_id"
    t.integer  "configuration_predictable_item_id"
    t.string   "predicted_value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "objectives_meet",                   :default => 0
    t.integer  "received_points",                   :default => 0
  end

  add_index "predictions", ["configuration_predictable_item_id"], :name => "index_predictions_on_configuration_predictable_item_id"
  add_index "predictions", ["user_id"], :name => "index_predictions_on_user_id"

  create_table "rpx_identifiers", :force => true do |t|
    t.string   "identifier",    :null => false
    t.string   "provider_name"
    t.integer  "user_id",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rpx_identifiers", ["identifier"], :name => "index_rpx_identifiers_on_identifier", :unique => true
  add_index "rpx_identifiers", ["user_id"], :name => "index_rpx_identifiers_on_user_id"

  create_table "score_table_positions", :force => true do |t|
    t.integer  "participation_id",      :null => false
    t.integer  "prediction_summary_id", :null => false
    t.integer  "contest_instance_id",   :null => false
    t.integer  "user_id",               :null => false
    t.integer  "position",              :null => false
    t.integer  "previous_position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "score_table_positions", ["contest_instance_id"], :name => "index_score_table_positions_on_contest_instance_id"
  add_index "score_table_positions", ["participation_id"], :name => "index_score_table_positions_on_participation_id"
  add_index "score_table_positions", ["prediction_summary_id"], :name => "index_score_table_positions_on_prediction_summary_id"
  add_index "score_table_positions", ["user_id"], :name => "index_score_table_positions_on_user_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "users", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email"
    t.string   "name"
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token",                               :null => false
    t.integer  "login_count",                     :default => 0,  :null => false
    t.datetime "last_request_at"
    t.datetime "last_login_at"
    t.datetime "current_login_at"
    t.string   "last_login_ip"
    t.string   "current_login_ip"
    t.string   "perishable_token",                :default => "", :null => false
    t.boolean  "allow_name_in_high_score_lists"
    t.boolean  "email_notifications_on_comments"
  end

  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["last_request_at"], :name => "index_users_on_last_request_at"
  add_index "users", ["perishable_token"], :name => "index_users_on_perishable_token"
  add_index "users", ["persistence_token"], :name => "index_users_on_persistence_token"

end
