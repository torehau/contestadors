require 'fastercsv'

namespace :predictable do
  namespace :championship do

    desc "Sets the result of a predictable and updates the prediction scores and score tables"
    task(:update_scores => :environment) do
      ActiveRecord::Base.transaction do
        
        puts "sets match scores..."
        @matches_by_id = {}
        Rake::Task["predictable:championship:set_match_scores"].invoke
        puts "found number of values: " + @matches_by_id.values.size.to_s

        puts "fetches the corresponding unsettled predictable items..."
        @unsettled_items_by_predictable_id = Predictable::Championship::PredictableItemsResolver.new(@matches_by_id.values).find_items
        
        @unsettled_items_by_predictable_id.values.each do |item|
          puts "... settles one item for set " + item.description
          item.settle!
        
          puts "fetches objectives for the item ..."
          objectives = item.set.objectives
          match = @matches_by_id[item.predictable_id]

          puts "updates predictions and summaries with scores ..."
          item.predictions.each do |prediction|
            puts "prediction for " + prediction.user.name
            prediction.set_score_for(match, objectives)
            prediction.save!
          end
          puts "...score updated for predictions"

          puts "sorts score table positions ..."
          Configuration::Contest.find_by_name("FIFA World Cup 2010").contest_instances.each {|ci| ci.update_score_table_positions}

          puts "marks predictable item as completely processed ..."
          item.complete!
        end
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
  end
end