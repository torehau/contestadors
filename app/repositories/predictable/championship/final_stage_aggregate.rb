module Predictable
  module Championship
    class FinalStageAggregate < StageAggregate
      def initialize(aggregate_root_id=nil, contest=nil)
        super(aggregate_root_id, contest)
      end

    protected

      def get_aggregate_root(aggregate_root_id)
        #aggregate_root_id = "final"
        Stage.from_permalink("final")
      end

      def set_match_winners
        @root.matches.each{|match| match.winner = @winners_by_match_id[match.id]}
        #@root.next.matches.each{|match| match.winner = @winners_by_match_id[match.id]} #TODO include for WC championship
      end

      def get_predictable_items
        #["Winner Team", "Third Place Team"].collect{|set_descr| @contest.set(set_descr)}.collect{|set| set.predictable_items}.flatten
        CommonContestCategoryItemsResolver.new.resolve(@contest, "Specific Team")
      end

      def save_new_aggregate_predictions
        save_match_winner("Winner Team", @root.matches_by_id)
        summary.predict_stage("Final")
        #TODO include for WC championship
        #save_match_winner("Third Place Team", @root.next.matches_by_id)
        #summary.predict_stage("Third Place")
      end

      # NOP, since no subsequent stages will be invalidated in this case
      def notify
      end

    private
    
      def save_match_winner(set_descr, matches_by_id)
        set = @contest.set(set_descr)

        Prediction.save_predictions(@user, set, matches_by_id) do |match|
          match.winner.id.to_s
        end
      end
    end
  end
end
