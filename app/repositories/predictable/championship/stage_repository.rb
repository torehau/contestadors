module Predictable
  module Championship
    class StageRepository < Repository

      def initialize(contest=nil, user=nil)
        super(contest, user)
      end

      # overriden default behaviour in super class for retreival of stage aggregates,
      # since all aggregates of this type should be retreived in addition to the current one.
      def get(aggregate_root_id)
        @aggregate = new_aggregate(aggregate_root_id)
        KnockoutStageResolver.new(@user).predicted_stages(@aggregate)
      end

    protected

      def new_aggregate(aggregate_root_id)
        return FinalStageAggregate.new(aggregate_root_id, @contest) if ["final", "completed"].include?(aggregate_root_id)
        StageAggregate.new(aggregate_root_id, @contest)
      end
    end
  end
end
