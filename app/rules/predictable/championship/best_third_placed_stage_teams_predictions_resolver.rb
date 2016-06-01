module Predictable
  module Championship
    class BestThirdPlacedStageTeamsPredictionsResolver
      include Ruleby

      def initialize(contest, user)
        @contest = contest
        @user = user
      end

      def resolve
        group_predictions = PredictionCollector.new(@contest, @user).get_all[:groups]
        third_place_positions = []
        ('A'..'F').each do |group_name|
          third_place_pos = group_predictions[group_name][:table]["3"]
          team = Predictable::Championship::Team.find(third_place_pos.predictable_championship_team_id)
          group_predictions[group_name][:matches].each do |match|
            if match.home_team.id == team.id
              scores = match.score.split("-")
              #set_individual_team_scores(scores[0],scores[1])
              third_place_pos.update_scores(scores[0].to_i,scores[1].to_i)
            elsif match.away_team.id == team.id
              scores = match.score.split("-")
              #set_individual_team_scores(scores[0],scores[1])
              third_place_pos.update_scores(scores[1].to_i,scores[0].to_i)
            end
          end
          third_place_positions << third_place_pos
        end
        third_place_positions.sort!{|a, b| b.pts == a.pts ? b.goal_diff <=> a.goal_diff : b.pts <=> a.pts }
      end
    end
  end
end
