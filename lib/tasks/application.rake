namespace :app do

  desc "Resets the database, migrates it to current version and loads all static date"
  task(:setup) do
    puts "dropping database..."
    Rake::Task["db:drop:all"].invoke
    puts "recreateing database..."
    Rake::Task["db:create:all"].invoke
    puts "migrating database schema..."
    Rake::Task["db:migrate"].invoke
    puts "loading data from csv files..."
    Rake::Task["csv2db:load_data"].invoke
  end

  namespace :updates do

    desc "For adding and populating new preview_available column to configuration_prediction_states table"
    task(:prediction_states) do
      puts "migrating database schema..."
      Rake::Task["db:migrate"].invoke

      puts "setting values of new points columns for configuration_prediction_states table..."
      Rake::Task["csv2db:update_prediction_states"].invoke
    end

    desc "Task for introducing contest score tables"
    task(:init_score_tables) do
      puts "migrating database schema..."
      Rake::Task["db:migrate"].invoke

      puts "creating score table positions for all existing contest participants ..."
      Rake::Task["app:updates:create_score_table_positions"].invoke

      puts "setting values of new points columns for configuration_prediction_states table..."
      Rake::Task["csv2db:update_prediction_states"].invoke

      puts "Updates map attribute for existing prediction summary entries ..."
      Rake::Task["app:updates:update_prediction_summary_maps"].invoke
    end

    desc "Creates ScoreTablePosition entries for all Participations not having this attribute"
    task(:create_score_table_positions => :environment) do
      Participation.find(:all).each do |participation|
        unless participation.score_table_position
          ScoreTablePosition.create!(:participation_id => participation.id,
                                     :contest_instance_id => participation.contest_instance.id,
                                     :prediction_summary_id => participation.user.summary_of(participation.contest_instance.contest).id,
                                     :user_id => participation.user.id,
                                     :position => 1)
        end
      end
    end

    desc "Updates the map for all existing PredictionSummary db entries."
    task(:update_prediction_summary_maps => :environment) do
      PredictionSummary.find(:all).each do |summary|
        prediction_state = Configuration::PredictionState.find_by_state_name(summary.state)
        summary.map = prediction_state.points_accumulated
        summary.save!
      end
    end
  end
end