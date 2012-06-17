module Predictable
  module Championship
    class Group < ActiveRecord::Base
      set_table_name("predictable_championship_groups")
      after_initialize :init_group
      has_many :table_positions, :class_name => "Predictable::Championship::GroupTablePosition", :foreign_key => "predictable_championship_group_id"
      has_many :teams, :through => :table_positions, :class_name => "Predictable::Championship::Team"
      has_many :qualifications, :class_name => "Predictable::Championship::GroupQualification", :foreign_key => "predictable_championship_group_id" do
        def for_winner
          where(:group_pos => 1).first
        end
        def for_runner_up
          where(:group_pos => 2).first
        end
      end

      attr_accessor :matches
      attr_accessor :winner, :runner_up

      # Returns a hash with the matches keyed by the id
      def matches_by_id
        Hash[*matches.collect{|match| [match.id, match]}.flatten]
      end

      def stage_teams_by_id        
        winner_team = winner_stage_team
        winner_team.team = @winner
        runner_up_team = runner_up_stage_team
        runner_up_team.team = @runner_up

        stage_teams_by_id = {}
        [winner_team, runner_up_team].each{|stage_team| stage_teams_by_id[stage_team.id] = stage_team}
        stage_teams_by_id
      end

      def promotion_stage
        self.qualifications.first.match.stage
      end

      def winner_stage_team
        #@@round_of_16 ||= Predictable::Championship::Stage.find_by_description("Round of 16")
        @@knockout_stage ||= promotion_stage
        winner_path ||= qualifications.for_winner
        stage_team(@@knockout_stage, winner_path, true)
      end

      def runner_up_stage_team
        #@@round_of_16 ||= Predictable::Championship::Stage.find_by_description("Round of 16")
        @@knockout_stage ||= promotion_stage
        runner_up_path ||= qualifications.for_runner_up
        stage_team(@@knockout_stage, runner_up_path, false)
      end

      # Returnes true if the group table contains tied teams with the same rank
      def is_rearrangable?
        table_positions.each {|position| return true if (position.can_move_up == true) or (position.can_move_down == true)}
        return false
      end

      # Assigns position and display order accoring to the sorted group table positions
      def sort_group_table(calculate_display_order)
        pos, increment, display_order = 0, 1, 1
        previous, current = nil, nil

        self.table_positions.sort!{|a, b| calculate_display_order ? (b <=> a) : (a.display_order <=> b.display_order)}.each do |table_position|
        #self.table_positions.sort!{|a, b| b <=> a }.each do |table_position|
          current = table_position

          #VM: unless previous and previous.is_tied_with?(current) and previous.rank == current.rank
          unless previous and previous.is_tied_with?(current) and previous.rank == current.rank and previous.goal_diff == current.goal_diff and previous.goals_for == current.goals_for and previous.team.ranking_coefficient == current.team.ranking_coefficient
            pos += increment
            increment = 1
          else
            increment += 1
            previous.can_move_down = true
            current.can_move_up = true
          end
          table_position.pos = pos

          if calculate_display_order
            table_position.display_order = display_order
            self.winner = table_position.team if display_order == 1
            self.runner_up = table_position.team if display_order == 2
            display_order += 1
          end
          previous = current
        end
      end

    private

      def init_group
        @matches = teams.collect {|t| t.group_matches}.flatten.uniq.sort
        @winner, @runner_up = nil, nil
      end

      def stage_team(stage, path, is_winner)
        Predictable::Championship::StageTeam.find(:first,
          :conditions => {:predictable_championship_stage_id => stage.id,
                          :predictable_championship_match_id => path.match.id,
                          :is_home_team => is_winner})
      end
    end
  end
end

