require 'fastercsv'

namespace :predictable do
  namespace :championship do

    desc "Sets the result of a predictable and updates the prediction scores and score tables"
    task(:update_scores => :environment) do
      ActiveRecord::Base.transaction do

        @contest = Configuration::Contest.find_by_name("FIFA World Cup 2010")
        @score_and_map_reduced_by_user_id = {}
        @user_by_id = {}
        @matches_by_id = {}
        
        puts "sets match scores..."        
        Rake::Task["predictable:championship:set_match_scores"].invoke
        puts "found number of values: " + @matches_by_id.values.size.to_s

        puts "fetches the corresponding unsettled predictable items..."
        @unsettled_items_by_predictable_id = Predictable::Championship::PredictableItemsResolver.new(@matches_by_id.values).find_items

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
        match.settle_match(@row.field(:score))
        puts "... score and result set for match " + match.home_team.name + " - " + match.away_team.name + " " + match.score + " (" + match.result + ")"
        @matches_by_id[match.id] = match
      end
    end

    desc "Calculates points for all predictions of unsettled predictable items."
    task(:set_prediction_points => :environment) do
      @unsettled_items_by_predictable_id.values.each do |item|
        puts "... settles one item for set " + item.description
        item.settle_predictions_for(@matches_by_id[item.predictable_id]) do |user, score, map_reduction|
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

    desc "Updates the prediction summaries of all users having prediction points set."
    task(:update_prediction_summaries => :environment) do
      @user_by_id.values.each do |user|
        score = @score_and_map_reduced_by_user_id[user.id][:score]
        map_reduction = @score_and_map_reduced_by_user_id[user.id][:map_reduction]
        summary = user.summary_of(@contest)
        summary.update_score_and_map_values(score, map_reduction)
        puts "prediction summary updated for " + user.name
      end
    end
  end
end