module Predictable
  module Championship

    class KnockoutStageResolver
      include Ruleby

      def initialize(user, contest)
        @contest = contest
        stage_ids = @contest.unique_aggregate_root_ids("stage")
        @stages = Predictable::Championship::Stage.order("id desc").find(stage_ids)
     #   group_ids = @contest.unique_aggregate_root_ids("group")
     #   groups = Predictable::Championship::Group.find(group_ids)
        @teams = Predictable::Championship::Team.where(:tournament_id => @contest.id).all#groups.collect {|group| group.teams}.flatten #Predictable::Championship::Team.find(:all)    # TODO change to only return teams for current contest
        @predictable_items = CommonContestCategoryItemsResolver.new.resolve(@contest, ["Stage Teams", "Specific Team"])#stage_predictable_items
        @predictions = user.predictions.for_items(@predictable_items)
       #VM:  @third_place_play_off = Predictable::Championship::Match.where("description = ?", "Third Place").last#@aggregate.associated
      end

      def predicted_stages(current_aggregate)
        @predicted_stages = {}

        engine :predicted_stage_matches do |e|
          KnockoutStageRulebook.new(e).rules(@predicted_stages)

          @teams.each {|team| e.assert team}
          @stages.each do |stage|
            stage.matches.each {|stage_match| e.assert stage_match}
            stage.stage_teams.each {|stage_team| e.assert stage_team}
            e.assert stage
          end
          
          @predictions.each{|prediction| e.assert prediction}
          @predictable_items.each{|item| e.assert item}
          #VM: e.assert @third_place_play_off
          
          e.match
        end

        result = Predictable::Result.new(current_aggregate, @predicted_stages, unpredicted_stages, invalidated_stages(current_aggregate))
        result.all_roots = @stages#VM: .select {|s| s.description != "Third place play-off"}
        #VM: resolve_third_place_play_off if is_semi_finals_predicted?
        #VM: result.aggregates_associated(:third_place, @third_place_play_off)
        result
      end

    private

      def unpredicted_stages
        unpredicted = {}
        @stages.each {|stage| unpredicted[stage.id] = stage unless @predicted_stages.has_key?(stage.id)}
        unpredicted
      end

      def invalidated_stages(current_aggregate)
        invalidated_stages = {}
        current_stage = current_aggregate.root

        while current_stage and current_stage.next do
          next_stage = current_stage.next
          invalidated_stages[next_stage.id] = next_stage if @predicted_stages.has_key?(next_stage.id)
          current_stage = next_stage
        end
        invalidated_stages
      end

      # TODO ruleify
      def is_semi_finals_predicted?
        @predicted_stages.size > 2
      end

#VM
      # TODO ruleify
      #def resolve_third_place_play_off
      #  semi_final_defeated_teams = []

      #  semi_finals_stage = Predictable::Championship::Stage.where("description = ?", "Semi finals").last
      #  @predicted_stages[semi_finals_stage.id].matches.each {|match| semi_final_defeated_teams << match.team_not_through_to_next_stage}

      # if semi_final_defeated_teams.size == 2
      #   @third_place_play_off.home_team = semi_final_defeated_teams[0]
#    @third_place_play_off.away_team = semi_final_defeated_teams[1]
#       end
#     end

    end
  end
end
