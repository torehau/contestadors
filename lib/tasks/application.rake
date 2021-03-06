namespace :app do

  desc "Resets the database, migrates it to current version and loads all static date"
  task(:setup) do
    puts "dropping database..."
    Rake::Task["db:drop:all"].invoke
    puts "recreateing database..."
    Rake::Task["db:create:all"].invoke
    puts "migrating database schema..."
    Rake::Task["db:migrate"].invoke
    puts "init operation settings"
    Rake::Task["app:updates:init_op_settings"].invoke
    puts "loading data from csv files..."
    Rake::Task["csv2db:load_data"].invoke
  end

  namespace :maintenance do
    desc "Initiates OperationSetting single row"
    task(:on => :environment) do
      op_setting = OperationSetting.first
      op_setting.is_under_maintenance = true
      op_setting.save!
    end

    desc "Initiates OperationSetting single row"
    task(:off => :environment) do
      op_setting = OperationSetting.first
      op_setting.is_under_maintenance = false
      op_setting.save!
    end
  end

  namespace :monitor do

    desc "Lists 10 last logged in users"
    task(:logins => :environment) do
      contest = Configuration::Contest.last
      User.order("last_request_at desc").limit(10).each {|user| puts user.name + (user.has_participated_in_previous_contests? ? "" : " (NEW)") + ": " + user.last_request_at.to_s + " state: " + user.summary_of(contest).state}
    end
    
    desc "Lists contest instances for the current tournament contest"
    task(:contests => :environment) do
      contest = Configuration::Contest.last
      ContestInstance.where(:configuration_contest_id => contest.id).each {|ci| puts ci.id.to_s + ". " + ci.name + " Admin: " + ci.admin.name + " Members/Invitations: " + ci.participations.active.count.to_s + "/" + ci.invitations.count.to_s + (ci.allow_join_by_url ? " Open" : " Closed") + " (Created " + ci.created_at.to_s(:short) + ")"}
    end
    
    desc "Lists stats for current tournament"
    task(:stats => :environment) do
      contest = Configuration::Contest.last
      puts "***** Stats for " + contest.name + " *****"
      ci_ids = ContestInstance.where(:configuration_contest_id => contest.id).select(:id)
      contest_count = ci_ids.count
      puts "Contest count: " + contest_count.to_s  
      users = User.all
      puts "Users count: " + users.count.to_s
      ps_count = PredictionSummary.where(:configuration_contest_id => contest.id).count
      puts "Users logged in for current contest: " + ps_count.to_s
      #user_ids = PredictionSummary.where(:configuration_contest_id => contest.id).select(:user_id)
      returning_user_count = 0
      #users = User.where(:id => user_ids)
      users.each do |u| 
        if u.prediction_summaries.for_contest(contest) and u.has_participated_in_previous_contests?
          returning_user_count += 1
        end        
      end
      puts "New users: " + (ps_count - returning_user_count).to_s
      puts "Returning users: " + returning_user_count.to_s
      ps_with_predictions_count = PredictionSummary.where("state != 'i' and configuration_contest_id = ? ", contest.id).count
      puts "Users with predictions: " + ps_with_predictions_count.to_s
      distinct_user_participants_count = Participation.where(:contest_instance_id => ci_ids).group(:user_id).count.count
      puts "Users participating in contests: " + distinct_user_participants_count.to_s
    end
    #PredictionSummary.order(:id).where(:configuration_contest_id => c.id).each {|ps| puts ps.user.name + " " + ps.state + (ps.user.has_participated_in_previous_contests? ? "" : " NEW")}    
    
      
    desc "Lists users having predicted the current tournament, but does not participate in any contest"
    task(:no_contest_users => :environment) do
      contest = Configuration::Contest.last
      puts "***** No contest users *****"
      users = User.all
      users.each do |u| 
        ps = u.prediction_summaries.for_contest(contest)
        if ps and ps.state != 'i' and u.participant_contests_instances(contest).empty?
          puts "Id: #{u.id} Name: #{u.name} Email: #{u.email}"
        end        
      end            
    end
    
    desc "lists 10 last entered comments"
    task(:comments => :environment) do
      Comment.order("created_at desc").limit(10).each {|c| puts c.user.name + (c.user.has_participated_in_previous_contests? ? "" : " (NEW)") + ", " + c.commentable.name + ": " + c.created_at.to_s(:short) + " Title: " + (c.title.nil? ? "" : c.title) + " Comment: " + c.body}
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
    
    desc "Creates HighScoreListPosition entry for all PredictionSummaries not having this attribute"
    task(:create_high_score_list_positions => :environment) do
      PredictionSummary.find(:all).each do |summary|
        unless summary.high_score_list_position
          HighScoreListPosition.create!(:prediction_summary_id => summary.id,
                                     :configuration_contest_id => summary.contest.id,
                                     :user_id => summary.user.id,
                                     :has_predictions => summary.state != 'i',
                                     :position => 1)
        end
      end
    end      
    
    desc "Update HighScoreListPosition entries for previous contests"
    task(:update_previous_contests_high_score_list_positions => :environment) do
      current = Configuration::Contest.last
      Configuration::Contest.where('id != ?', current.id).each do |contest|
          contest.update_high_score_list_positions
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
    
    desc "Initiates OperationSetting single row"
    task(:init_op_settings => :environment) do
      op_setting = OperationSetting.new
      op_setting.is_under_maintenance = false
      op_setting.admin_user = "contestadors@gmail.com"
      op_setting.save!
    end
  end

  desc "Reset all users' password to 'inspect''"
  task(:inspect_users => :environment) do
    User.all.each {|user| user.update_attributes(:password => "inspect", :password_confirmation => "inspect")}
  end
end
