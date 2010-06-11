module Predictable
  module Championship
    class PredictableItemsResolver
      include Ruleby

      def initialize(predictables, predictable_item_state=:unsettled)
        @preditables = predictables
        @predictable_item_state = predictable_item_state
        @items_by_predictable_id = {}
      end

      def find_items
        engine :predictable_items_resolver do |e|
          rulebook = PredictableItemsRulebook.new(e)
          rulebook.items_by_predictable_id = @items_by_predictable_id
          rulebook.rules(@predictable_item_state)
          @preditables.each {|predictable| e.assert predictable}
          Configuration::Category.find_by_description("Group Matches").predictable_items.each {|item| e.assert item}

          e.match
        end
        @items_by_predictable_id
      end

    private

      class PredictableItemsRulebook < Ruleby::Rulebook

        attr_accessor :items_by_predictable_id

        def rules(predictable_item_state)
          group_matches_items_rule(predictable_item_state)
        end

      private

        def group_matches_items_rule(predictable_item_state)
           rule :group_matches_items,# {:priority => 4},
             [Predictable::Championship::Match, :group_match,
               {m.id => :group_match_id}],
             [Configuration::PredictableItem, :group_match_item,
               m.state_name == predictable_item_state,
               m.predictable_id == b(:group_match_id)] do |v|

               @items_by_predictable_id[v[:group_match].id] = v[:group_match_item]
               retract v[:group_match]
               retract v[:group_match_item]
          end
        end
      end
    end
  end
end
