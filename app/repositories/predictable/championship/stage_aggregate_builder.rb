module Predictable
  module Championship
    class StageAggregateBuilder
      def initialize(stage_permalink, contest)
        @root = Stage.from_permalink(stage_permalink)
        @contest = contest
      end

      # deprecated not in use
      def build_from_new(predicted_winners_by_match_id)
        @winners = {}
        predicted_winners_by_match_id.each do |match_id, match|
          @winners[match_id.to_i] = Predictable::Championship::Team.find(match[:winner].to_i)
        end
        @root.matches.each{|match| match.winner = @winners[match.id]}
        @root
      end

      # deprecated to simple
      def build_from_existing(user)
        KnockoutStageResolver.new(user, @contest).predicted_stages(@root)
      end
    end
  end
end
