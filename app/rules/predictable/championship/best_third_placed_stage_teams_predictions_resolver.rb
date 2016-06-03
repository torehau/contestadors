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
              third_place_pos.update_scores(scores[0].to_i,scores[1].to_i)
            elsif match.away_team.id == team.id
              scores = match.score.split("-")
              third_place_pos.update_scores(scores[1].to_i,scores[0].to_i)
            end
            third_place_pos.team = team
          end
          third_place_positions << third_place_pos
        end
        third_place_positions.sort!{|a, b| b.pts == a.pts ? (b.goal_diff == a.goal_diff ? (b.goals_for == a.goals_for ? b.team.ranking_coefficient <=> a.team.ranking_coefficient : b.goals_for <=> a.goals_for) :  b.goal_diff <=> a.goal_diff) : b.pts <=> a.pts }
        groups = []
        third_place_positions[0..3].each{|gtp| groups << gtp.group.name}
        groups.sort!
        permutation = ""
        groups.each{|g| permutation += g}
        best_ranked_groups = Predictable::Championship::BestRankedGroup.where(:permutation => permutation).first
        stage_teams = []
        third_place_positions[0..3].each do |gtp|
          qualification = Predictable::Championship::ThirdPlaceGroupTeamQualification.where(:predictable_championship_best_ranked_group_id => best_ranked_groups.id, :predictable_championship_group_id => gtp.group.id).first
          stage_team = qualification.stage_team
          stage_team.team = gtp.team
          stage_teams << stage_team
        end
        predictable_item_by_stage_team_id = Predictable::Championship::PredictableItemsResolver.new(@contest, stage_teams).find_items("Stage Teams")
        predictions = []
        stage_teams.each do |st|
          item = predictable_item_by_stage_team_id[st.id]
          prediction = @user.prediction_for(item)

          if prediction.nil?
            prediction = Prediction.new
            prediction.user_id = @user.id
            prediction.configuration_predictable_item_id = item.id
          end
          prediction.predicted_value = st.team.id.to_s
          predictions << prediction
        end
        predictions
      end
    end
  end
end
