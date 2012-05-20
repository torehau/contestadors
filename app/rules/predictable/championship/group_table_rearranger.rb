module Predictable
  module Championship

    # swaps two teams at adjugate positions of the group table, if this is valid
    # e.g., if the teams really are tied.
    class GroupTableRearranger
      include Ruleby

      def initialize(group, user, contest, params)
        @group = group
        @user = user
        @contest = contest
        @position_id, @table_position, @move_direction = params[:team_id], params[:pos], params[:command]
        @group_table_set = @contest.set("Group #{@group.name} Table")
        @promotion_stage_set = get_promotion_stage_set#Configuration::Set.find_by_description "Teams through to Round of 16"
        @predictions_to_update, @updated_prediction_values, @group_table_positions_to_swap = [], {}, {}
      end

      # returns the predictions needed to be updated and with which values, and
      # swaps the group table positions for the group.
      def rearrange

        engine :rearrange_group_table do |e|
          rulebook = RearrangableGroupTableValidationRulebook.new(e)
          rulebook.rules("Group #{@group.name} Table", @position_id.to_i, @table_position, @move_direction, @promotion_stage_set.description)
          rulebook.predictions_to_update = @predictions_to_update
          rulebook.updated_prediction_values = @updated_prediction_values
          rulebook.group_table_positions_to_swap = @group_table_positions_to_swap

          e.assert @group_table_set
          @group_table_set.predictable_items.each{|item| e.assert item}
          @user.predictions_for(@group_table_set).each{|prediction| e.assert prediction}

          e.assert @promotion_stage_set
          items = @promotion_stage_set.subset(@group.stage_teams_by_id.keys)
          items.each {|item| e.assert item}
          @user.predictions_for_subset(items).each{|prediction| e.assert prediction}
          
          @group.table_positions.each{|table_position| e.assert table_position}
          e.assert @group.runner_up_stage_team

          e.match
        end

        unless @group_table_positions_to_swap.empty?
          swap_group_table_positions(@group_table_positions_to_swap[:up], @group_table_positions_to_swap[:down])

          @predictions_to_update.each do |prediction|
            prediction.predicted_value = @updated_prediction_values[prediction.id]
          end
        end
        @predictions_to_update
      end

    private

      def get_promotion_stage_set
        stage = @group.promotion_stage
        @contest.set("Teams through to #{stage.description}")#Configuration::Set.find_by_description "Teams through to Round of 16"
      end

      class ValidRearrangement; end

      class RearrangableGroupTableValidationRulebook < Ruleby::Rulebook
        
        attr_accessor :predictions_to_update, :updated_prediction_values, :group_table_positions_to_swap

        def rules(group_descr, position_id, table_position, move_direction, promotion_stage_set_descr)
          @current_value = table_position.to_i
          @updated_value = move_direction.eql?("up") ? (@current_value - 1) : (@current_value + 1)

          if move_direction.eql?("up")
            move_team_up_rule(position_id, group_descr, table_position)
          else
            move_team_down_rule(position_id, group_descr, table_position)
          end

          if [@current_value, @updated_value].include?(1)
            swap_predictions_for_winner_and_runner_up_rule(promotion_stage_set_descr)
          elsif [@current_value, @updated_value].include?(2) and [@current_value, @updated_value].include?(3)
            swap_predictions_for_runner_up_and_third_place_rule(group_descr, promotion_stage_set_descr)
          end
        end

        def move_team_up_rule(position_id, group_descr, table_position)

          rule :move_team_up, {:priority => 2},
             [Configuration::Set, :group_table_set,
               m.description == group_descr,
              {m.id => :group_table_set_id}],
             [Configuration::PredictableItem, :group_position_item,
               m.configuration_set_id == b(:group_table_set_id),
               m.predictable_id == position_id,
              {m.id => :group_position_item_id}],
             [Prediction, :prediction,
               m.configuration_predictable_item_id == b(:group_position_item_id),
               m.predicted_value == table_position],
             [Predictable::Championship::GroupTablePosition, :current_position,
               m.id == position_id,
               m.display_order==@current_value,
               m.can_move_up == true],
             [Configuration::PredictableItem, :other_group_position_item,
               m.configuration_set_id == b(:group_table_set_id),
               m.id.not== b(:group_position_item_id),
              {m.id => :other_group_position_item_id, m.predictable_id => :other_group_position_id}],
             [Prediction, :prediction_to_swap_with,
               m.configuration_predictable_item_id == b(:other_group_position_item_id),
               m.predicted_value(&c{|val| @updated_value.to_s.eql?(val)})],
             [Predictable::Championship::GroupTablePosition, :updated_position,
               m.id == b(:other_group_position_id),
               m.display_order==@updated_value,
               m.can_move_down == true] do |v|

#            puts "***** Fires - move up"

            assert ValidRearrangement.new
            register_prediction_for_update(v[:prediction], @updated_value)
            register_prediction_for_update(v[:prediction_to_swap_with], @current_value)
            @group_table_positions_to_swap[:up] = v[:current_position]
            @group_table_positions_to_swap[:down] = v[:updated_position]
          end
        end

        def move_team_down_rule(position_id, group_descr, table_position)
          rule :move_team_down, {:priority => 2},
             [Configuration::Set, :group_table_set,
               m.description == group_descr,
              {m.id => :group_table_set_id}],
             [Configuration::PredictableItem, :group_position_item,
               m.configuration_set_id == b(:group_table_set_id),
               m.predictable_id == position_id,
              {m.id => :group_position_item_id}],
             [Prediction, :prediction,
               m.configuration_predictable_item_id == b(:group_position_item_id),
               m.predicted_value == table_position],
             [Predictable::Championship::GroupTablePosition, :current_position,
               m.id == position_id,
               m.display_order==@current_value,
               m.can_move_down == true],
             [Configuration::PredictableItem, :other_group_position_item,
               m.configuration_set_id == b(:group_table_set_id),
               m.id.not== b(:group_position_item_id),
              {m.id => :other_group_position_item_id, m.predictable_id => :other_group_position_id}],
             [Prediction, :prediction_to_swap_with,
               m.configuration_predictable_item_id == b(:other_group_position_item_id),
               m.predicted_value(&c{|val| @updated_value.to_s.eql?(val)})],
             [Predictable::Championship::GroupTablePosition, :updated_position,
               m.id == b(:other_group_position_id),
               m.display_order==@updated_value,
               m.can_move_up == true] do |v|

#            puts "***** Fires - move down"

            assert ValidRearrangement.new
            register_prediction_for_update(v[:prediction], @updated_value)
            register_prediction_for_update(v[:prediction_to_swap_with], @current_value)
            @group_table_positions_to_swap[:up] = v[:updated_position]
            @group_table_positions_to_swap[:down] = v[:current_position]
          end
        end

        def swap_predictions_for_winner_and_runner_up_rule(promotion_stage_set_description)
          rule :swap_stage_team_predictions_for_winner_and_runner_up, {:priority => 1},
           [ValidRearrangement, :valid_rearrangement],
           [Configuration::Set, :promotion_stage_set,
             m.description == promotion_stage_set_description,
            {m.id => :stage_teams_set_id}],
           [Configuration::PredictableItem, :stage_team_item,
             m.configuration_set_id == b(:stage_teams_set_id),
            {m.id => :stage_team_item_id}],
           [Prediction, :prediction,
             m.configuration_predictable_item_id == b(:stage_team_item_id)],
           [Configuration::PredictableItem, :other_stage_team_item,
             m.configuration_set_id == b(:stage_teams_set_id),
             m.id.not== b(:stage_team_item_id),
            {m.id => :other_stage_team_item_id}],
           [Prediction, :prediction_to_swap_with,
             m.configuration_predictable_item_id == b(:other_stage_team_item_id)] do |v|

#            puts "***** Fires - swap winner and runner up"

            first_val = v[:prediction].predicted_value
            second_val = v[:prediction_to_swap_with].predicted_value

            register_prediction_for_update(v[:prediction], second_val)
            register_prediction_for_update(v[:prediction_to_swap_with], first_val)

            retract v[:valid_rearrangement]
            retract v[:prediction]
            retract v[:prediction_to_swap_with]
          end
        end
        
        def swap_predictions_for_runner_up_and_third_place_rule(group_descr, promotion_stage_set_descr)
          rule :set_current_third_place_group_position_as_runner_up_stage_team, {:priority => 1},
            [ValidRearrangement, :valid_rearrangement],
            [Predictable::Championship::StageTeam, :group_runner_up_stage_team,
              {m.id => :stage_team_id}],
            [Configuration::Set, :promotion_stage_set,
              m.description == promotion_stage_set_descr,
             {m.id => :stage_teams_set_id}],
            [Configuration::PredictableItem, :stage_team_item,
              m.configuration_set_id == b(:stage_teams_set_id),
              m.predictable_id == b(:stage_team_id),
             {m.id => :stage_team_item_id}],
            [Prediction, :runner_up_prediction,
              m.configuration_predictable_item_id == b(:stage_team_item_id)],
            [Configuration::Set, :group_table_set,
              m.description == group_descr,
             {m.id => :group_table_set_id}],
            [Configuration::PredictableItem, :group_position_predictable_item,
              m.configuration_set_id == b(:group_table_set_id),
             {m.id => :group_position_item_id, m.predictable_id => :third_place_pos_id}],
            [Prediction, :third_place_prediction,
              m.configuration_predictable_item_id == b(:group_position_item_id),
              m.predicted_value == "3"],
            [Predictable::Championship::GroupTablePosition, :current_third_place_position,
              m.id == b(:third_place_pos_id)] do |v|

#            puts "***** Fires - swap runner up and third place"

            register_prediction_for_update(v[:runner_up_prediction], v[:current_third_place_position].team.id)

            retract v[:valid_rearrangement]
            retract v[:runner_up_prediction]
            retract v[:group_runner_up_stage_team]
          end
        end

      private

        def register_prediction_for_update(prediction, updated_value)
          @predictions_to_update << prediction
          @updated_prediction_values[prediction.id] = updated_value.to_s
        end
      end

      def swap_group_table_positions(up, down)
        current_up_position = up.display_order
        up.display_order = down.display_order
        up.can_move_up = down.can_move_up

        down.display_order = current_up_position
        down.can_move_down = up.can_move_down
      end
    end
  end
end
