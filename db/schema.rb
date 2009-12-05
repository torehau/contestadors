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

ActiveRecord::Schema.define(:version => 20091205142106) do

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

  create_table "configuration_sets", :force => true do |t|
    t.string   "description"
    t.boolean  "mutex_objectives"
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

end
