module Predictable
  module Championship

    class KnockoutStageResolver
      include Ruleby

      def initialize(aggregate)
        @aggregate = aggregate
        @stages = Predictable::Championship::Stage.knockout_stages
        @teams = Predictable::Championship::Team.find(:all)        
        @predictable_items = stage_predictable_items
        @predictions = @aggregate.user.predictions.for_items(@predictable_items)
        @third_place_play_off = @aggregate.associated
      end

      def predicted_stages
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
          e.assert @third_place_play_off
          
          e.match
        end

        @aggregate.all_predicted_roots = @predicted_stages
        
        if @aggregate.is_editing_existing_predictions?
          @aggregate.all_invalidated_roots = get_stages_invalidated_by_edit
        end
        resolve_third_place_play_off if is_semi_finals_predicted?
        @aggregate
      end

      private

      def stage_predictable_items
        ["Stage Teams", "Specific Team"].collect{|category_descr| Configuration::Category.find_by_description(category_descr)}.collect{|category| category.predictable_items}.flatten
      end

      def get_stages_invalidated_by_edit
        invalidated_stage = []
        current_stage = @aggregate.root

        while current_stage.next do
          invalidated_stage << current_stage.next.id
          current_stage = current_stage.next
        end
        invalidated_stage
      end

      def last_predicted_stage

        for stage in @predicted_stages.values
          unless @predicted_stages.values.include?(stage.next)
            return stage
          end
        end
        @predicted_stages.values.first
      end

      def is_semi_finals_predicted?
        @aggregate.all_predicted_roots.size > 2
      end

      def resolve_third_place_play_off
        semi_final_defeated_teams = []

        semi_finals_stage = Predictable::Championship::Stage.find_by_description("Semi finals")
        @aggregate.all_predicted_roots[semi_finals_stage.id].matches.each {|match| semi_final_defeated_teams << match.team_not_through_to_next_stage}

        if semi_final_defeated_teams.size == 2
          @aggregate.associated.home_team = semi_final_defeated_teams[0]
          @aggregate.associated.away_team = semi_final_defeated_teams[1]
        end
      end
    end
  end
end
