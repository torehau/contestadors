require 'fastercsv'

namespace :predictable do
  namespace :championship do

    desc "Sets the result of a predictable and updates the prediction scores and score tables"
    task(:update_scores => :environment) do
      ActiveRecord::Base.transaction do

        @contest = Configuration::Contest.find_by_name("FIFA World Cup 2010")
        @score_and_map_reduced_by_user_id = {}
        @user_by_id = {}
        @predictable_types = {:group_matches => "Group Matches", :group_positions => "Group Tables", :stage_teams => "Stage Teams"}
        @predictables_by_id = {}
        @predictable_types.keys.each {|predictable_type| @predictables_by_id[predictable_type] = {}}
        @unsettled_items_by_predictable_id = {}
        
        puts "sets match scores..."        
        Rake::Task["predictable:championship:set_match_scores"].invoke
        puts "found number of matches: " + @predictables_by_id[:group_matches].values.size.to_s

        puts "sets group table positions..."
        Rake::Task["predictable:championship:set_group_positions"].invoke
        puts "found number of group positions: " + @predictables_by_id[:group_positions].values.size.to_s

        puts "sets stage teams..."
        Rake::Task["predictable:championship:set_stage_teams"].invoke
        puts "found number of stage teams: " + @predictables_by_id[:stage_teams].values.size.to_s
        
        @predictable_types.each do |predictable_type, category_descr|
          puts "fetches the corresponding unsettled " + predictable_type.to_s.gsub('_', ' ') + " predictable items..."
          @unsettled_items_by_predictable_id[predictable_type] = Predictable::Championship::PredictableItemsResolver.new(@predictables_by_id[predictable_type].values).find_items(category_descr)
          puts "found number of unsettled " + predictable_type.to_s.gsub('_', ' ') + " predictable items: " + @unsettled_items_by_predictable_id[predictable_type].size.to_s
        end

        puts "sets prediction score points and objectives meet..."
        Rake::Task["predictable:championship:set_prediction_points"].invoke

        puts "updates prediction summaries ..."
        Rake::Task["predictable:championship:update_prediction_summaries"].invoke

        puts "update all contest score tables ..."
        @contest.update_all_score_tables

        puts "... score update completed."
      end
    end
    
    desc "Sets the score and result for matches listed in the CSV file."
    task(:set_match_scores => :environment) do
      file_name = File.join(File.dirname(__FILE__), '/predictable_championship_match_results.csv')
      parser = FasterCSV.new(File.open(file_name, 'r'),
                             :headers => true, :header_converters => :symbol,
                             :col_sep => ',')

      parser.each do |@row|
        home_team = Predictable::Championship::Team.find_by_name(@row.field(:home_team_name))
        away_team = Predictable::Championship::Team.find_by_name(@row.field(:away_team_name))
        match = Predictable::Championship::Match.find(:first, :conditions => {:description => @row.field(:match_descr), :home_team_id => home_team.id, :away_team_id => away_team.id})
        match ||= Predictable::Championship::Match.find(:first, :conditions => {:description => @row.field(:match_descr), :home_team_id => away_team.id, :away_team_id => home_team.id})
        match.settle_match(@row.field(:score))
        puts "... score and result set for match " + match.home_team.name + " - " + match.away_team.name + " " + match.score + " (" + match.result + ")"
        if match.is_group_match?
          @predictables_by_id[:group_matches][match.id] = match
        else
          stage_team = match.winner_stage_team
          @predictables_by_id[:stage_teams][stage_team.id] = stage_team
        end
      end
    end

    desc "Sets the score and result for matches listed in the CSV file."
    task(:set_group_positions => :environment) do
      file_name = File.join(File.dirname(__FILE__), '/predictable_championship_group_positions.csv')
      parser = FasterCSV.new(File.open(file_name, 'r'),
                             :headers => true, :header_converters => :symbol,
                             :col_sep => ',')

      parser.each do |@row|        
        group = Predictable::Championship::Group.find_by_name(@row.field(:group))
        puts "Found group: " + group.name
        team = Predictable::Championship::Team.find_by_name(@row.field(:team))
        puts "Found team: " + team.name
        group_table_position = Predictable::Championship::GroupTablePosition.find(:first, :conditions => {:predictable_championship_group_id => group.id, :predictable_championship_team_id => team.id})
        group_table_position.settle(@row.field(:pos))
        
        puts group_table_position.pos.to_s + ". position group " + group_table_position.group.name + ": " + group_table_position.team.name
        @predictables_by_id[:group_positions][group_table_position.id] = group_table_position
      end
    end

    desc "Sets the score and result for matches listed in the CSV file."
    task(:set_stage_teams => :environment) do
      file_name = File.join(File.dirname(__FILE__), '/predictable_championship_stage_teams.csv')
      parser = FasterCSV.new(File.open(file_name, 'r'),
                             :headers => true, :header_converters => :symbol,
                             :col_sep => ',')

      parser.each do |@row|
        stage = Predictable::Championship::Stage.find_by_description(@row.field(:stage))
        team = Predictable::Championship::Team.find_by_name(@row.field(:team))
        
        if stage and team
          stage_team = Predictable::Championship::StageTeam.find(:first, :conditions => {:predictable_championship_stage_id => stage.id, :predictable_championship_team_id => team.id})

          puts "Stage: " + stage_team.stage.description + ", Team: " + stage_team.team.name
          @predictables_by_id[:stage_teams][stage_team.id] = stage_team
        end
      end
    end

    desc "Calculates points for all predictions of unsettled group match predictable items."
    task(:set_prediction_points => :environment) do
      @predictable_types.each do |predictable_type, category_descr|
        unless "Stage Teams".eql?(category_descr)
          @unsettled_items_by_predictable_id[predictable_type].values.each do |item|
            puts "... settles one item for set " + item.description
            item.settle_predictions_for(@predictables_by_id[predictable_type][item.predictable_id]) do |user, score, map_reduction|
              unless @user_by_id.has_key?(user.id)
                @user_by_id[user.id] = user
                @score_and_map_reduced_by_user_id[user.id] = {:score => score, :map_reduction => map_reduction}
              else
                @score_and_map_reduced_by_user_id[user.id][:score] += score
                @score_and_map_reduced_by_user_id[user.id][:map_reduction] += map_reduction
              end
            end
          end
        else
          items = @unsettled_items_by_predictable_id[predictable_type].values
          
          third_place_set = Configuration::Set.find_by_description("Third Place Team")
          third_place_item = third_place_set.predictable_items.first
          winner_set = Configuration::Set.find_by_description("Winner Team")
          winner_item = winner_set.predictable_items.first
          dependant_items_by_item_id = {}
          points_giving_value, map_reduction_value  = nil, nil
          
          if items.size > 1
            items.each do |item|
              stage_team = item.predictable
              dependant_items = Predictable::Championship::PredictableItemsResolver.new(stage_team.dependant_predictables).find_items(category_descr)
              dependant_items_by_item_id[item.id] = dependant_items.values
              dependant_items_by_item_id[item.id] << third_place_item
              dependant_items_by_item_id[item.id] << winner_item
            end

          else
            item = items.first
            stage_team = item.predictable
            match = stage_team.qualified_from_match
            following_stage_teams = Predictable::Championship::StageTeam.stage_teams_after(stage_team.stage)
            dependant_items = Predictable::Championship::PredictableItemsResolver.new(following_stage_teams).find_items(category_descr)
            dependant_items_by_item_id[item.id] = dependant_items.values
            dependant_items_by_item_id[item.id] << third_place_item
            dependant_items_by_item_id[item.id] << winner_item
            map_reduction_value = match.losing_team.id.to_s
          end

          Configuration::PredictableItem.settle_predictions_for(items, dependant_items_by_item_id, map_reduction_value) do |user, score, map_reduction|
            unless @user_by_id.has_key?(user.id)
              @user_by_id[user.id] = user
              @score_and_map_reduced_by_user_id[user.id] = {:score => score, :map_reduction => map_reduction}
            else
              @score_and_map_reduced_by_user_id[user.id][:score] += score
              @score_and_map_reduced_by_user_id[user.id][:map_reduction] += map_reduction
            end
          end
        end
      end
    end

    desc "Updates the prediction summaries of all users having prediction points set."
    task(:update_prediction_summaries => :environment) do
      @user_by_id.values.each do |user|
        score = @score_and_map_reduced_by_user_id[user.id][:score]
        map_reduction = @score_and_map_reduced_by_user_id[user.id][:map_reduction]
        summary = user.summary_of(@contest)
        if summary
          summary.update_score_and_map_values(score, map_reduction)
          puts "prediction summary updated for " + user.name
        end
      end
    end

    desc "Sets up dev application in dev mode"
    task(:dev_setup => :environment) do
      puts "get most recent db changes..."
      Rake::Task["db:migrate"].invoke
      puts "set default password for all users to 'changeit' "
      User.find(:all).each {|user| user.update_attributes(:password => 'changeit', :password_confirmation => 'changeit')}
      puts "correct data error in stage_qualifications table"
      Rake::Task["predictable:championship:correct_stage_qualifications"].invoke
    end

    desc "Correct stage qualifications to set final stage teams as SF match winners, and third place PO stage teams as SF match loosers"
    task(:correct_stage_qualifications => :environment) do
      third_place = Predictable::Championship::Match.find_by_description("Third Place")
      third_place_stage_teams = Predictable::Championship::StageTeam.find(:all, :conditions => {:predictable_championship_match_id => third_place.id})
      stage_team_ids = third_place_stage_teams.collect {|tpst| tpst.id}
      Predictable::Championship::StageQualification.find(:all, :conditions => {:predictable_championship_stage_team_id => stage_team_ids}).each do |qual|
        qual.is_winner = false
        qual.save!
      end
      final = Predictable::Championship::Match.find_by_description("Final")
      final_stage_teams = Predictable::Championship::StageTeam.find(:all, :conditions => {:predictable_championship_match_id => final.id})
      stage_team_ids = final_stage_teams.collect {|tpst| tpst.id}
      Predictable::Championship::StageQualification.find(:all, :conditions => {:predictable_championship_stage_team_id => stage_team_ids}).each do |qual|
        qual.is_winner = true
        qual.save!
      end
    end

    desc "Correcting user with predictions on one account and predictions on another account"
    task(:merge_users => :environment) do
      u1 = User.find(141)
      puts "User 1 " + u1.name
      u2 = User.find(189)
      puts "User 1 " + u2.name
      contest = Configuration::Contest.find(:first)

      ActiveRecord::Base.transaction do
        u1.participations.each do |participation|
          participation.user = u2
          participation.save!
        end
        u1.score_table_positions.each do |stp|
          stp.user = u2
          stp.prediction_summary = u2.summary_of(contest)
          stp.save!
        end
      end
    end

    desc "Correcting predictions placed incorrectly using IE"
    task(:correct_predictions => :environment) do
      user = User.find(76)

# 1/4 finale
#Paraguay - Spania    Spania
#Argentina - Tyskland      Argentina
#Frankrike - England    England
#Holland - Brasil                    Brasil
#
# Semi
#ARG - SPA    Spania
#ENG - BRA         Brasil
#
#  vinner av finalen SPA-BRA?    Spania
#
#  vinner av 3. plass ENG-ARG? Argentina

      paraguay = Predictable::Championship::Team.find_by_name("Paraguay")
      netherlands = Predictable::Championship::Team.find_by_name("Netherlands")
      argentina = Predictable::Championship::Team.find_by_name("Argentina")
      england = Predictable::Championship::Team.find_by_name("England")
      spain = Predictable::Championship::Team.find_by_name("Spain")
      brazil = Predictable::Championship::Team.find_by_name("Brazil")
      france = Predictable::Championship::Team.find_by_name("France")

      set = Configuration::Set.find_by_description("Teams through to Semi finals")
      user.predictions_for(set).each do |prediction|

        if prediction.predicted_value.eql?(netherlands.id.to_s)
          prediction.predicted_value = brazil.id.to_s
          prediction.save!
        elsif prediction.predicted_value.eql?(paraguay.id.to_s)
          prediction.predicted_value = spain.id.to_s
          prediction.save!
        elsif prediction.predicted_value.eql?(france.id.to_s)
          prediction.predicted_value = england.id.to_s
          prediction.objectives_meet = nil
          prediction.received_points = nil
          prediction.save!
        end
      end

      set = Configuration::Set.find_by_description("Teams through to Final")
      user.predictions_for(set).each do |prediction|

        if prediction.predicted_value.eql?(france.id.to_s)
          prediction.predicted_value = brazil.id.to_s
          prediction.objectives_meet = nil
          prediction.received_points = nil
          prediction.save!
        elsif prediction.predicted_value.eql?(argentina.id.to_s)
          prediction.predicted_value = spain.id.to_s
          prediction.save!
        end
      end

      set = Configuration::Set.find_by_description("Third Place Team")
      Prediction.create!(:user_id => user.id,
        :configuration_predictable_item_id => set.predictable_items.first.id,
        :predicted_value => argentina.id.to_s)
#      user.predictions_for(set).each do |prediction|
#        prediction.predicted_value = argentina.id.to_s
#        prediction.save!
#      end

      set = Configuration::Set.find_by_description("Winner Team")
      Prediction.create!(:user_id => user.id,
        :configuration_predictable_item_id => set.predictable_items.first.id,
        :predicted_value => spain.id.to_s)
#      user.predictions_for(set).each do |prediction|
#        prediction.predicted_value = spain.id.to_s
#        prediction.save!
#      end
      contest = Configuration::Contest.find(:first)
      summary = user.summary_of(contest)
      summary.map = summary.map + 16 + 9
      summary.previous_map = summary.previous_map + 16 + 9
      summary.state = "t"
      summary.save!
    end
  end
end