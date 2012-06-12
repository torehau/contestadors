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

  namespace :monitor do

    desc "Lists 10 last logged in users"
    task(:logins => :environment) do
      User.order("last_request_at desc").limit(10).each {|user| puts user.name + ": " + user.last_request_at.to_s}
    end
  end

  namespace :contests do

    desc "Configures a new championship prediction contest"
    task(:add) do
      puts "loading data from csv files..."
      Rake::Task["csv2db:add_championship_contest"].invoke
    end

    desc "Deletes test contest instances"
    task(:delete => :environment) do
      ids = [53, 54, 55, 56, 58, 64, 68]
      ContestInstance.where(:id => ids).each do |ci|
        puts "Deletes contest '" + ci.name + "', administered by " + ci.admin.name
        ContestInstance.delete(ci)
      end
    end
  end

  namespace :contest do

    namespace :participant do

      desc "Adds a new participant based on an invitation token"
      task(:add => :environment) do
        user = User.find(142)
        invite_code = "2c7bc6a7-282c-51ae-b472-2c9ccbdf1f06"
        invitation = Invitation.find_by_token(invite_code)

        if invitation
          contest_instance = invitation.contest_instance

          if invitation.is_accepted?
            puts "You have already accepted the invitation for the '#{contest_instance.name}' contest."
            return
          end
          participation = Participation.new(:user_id => user.id,
                               :contest_instance_id => contest_instance.id,
                               :invitation_id => invitation.id,
                               :active => true)

          if participation.save
            puts "You have now successfully accepted the invitation and joined the '#{contest_instance.name}' contest."
          else
            raise "Failed to accept invitation with invite code: " + invite_code
          end
        else
          raise "Failed to find invitation with invite code: " + (invite_code ? invite_code : "nil")
        end
      end
    end
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

  desc "Reset all users' password to 'inspect''"
  task(:inspect_users => :environment) do
    User.all.each {|user| user.update_attributes(:password => "inspect", :password_confirmation => "inspect")}
  end
end