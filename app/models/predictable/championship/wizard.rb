module Predictable
  module Championship
    module Wizard
      module InstanceMethods

        attr_accessor :current_step, :next_step, :selected_step_type, :selected_step_id, :all_available_steps, :prediction_progress

        def start_hint
          "Start to predict the match results for Group A"
        end

        def is_completed?
          self.contest.last_prediction_state("stage").permalink.eql?(self.current_step)
        end

        def update_wizard(step_type=nil, step_id=nil)
          self.selected_step_type = step_type
          self.selected_step_id = step_id
          current_prediction_state = contest.prediction_state(state)
          self.prediction_progress = current_prediction_state.progress_accumulated
          self.current_step = current_prediction_state.permalink
          next_prediction_state = current_prediction_state.next
          self.next_step = next_prediction_state ? next_prediction_state.permalink : nil
          self.all_available_steps = collect_available_steps

          #self.prediction_progress = 0
          #self.current_step = "i"
          #self.next_step = nil#"A"
          #self.all_available_steps = collect_available_steps
        end

        def collect_available_steps
          steps = []
          groups_complete = is_all_groups_predicted?
          last_group_state = contest.last_prediction_state("group")
          last_available_group = groups_complete ? last_group_state.permalink : self.next_step
          ('A'..last_available_group).each{|group_name| steps << GroupWizardStep.new(group_name)}

          if is_completed?
            stage_step_id = self.selected_step_type == "stage" ? self.selected_step_id : "completed"
            steps << StageWizardStep.new(stage_step_id)
          elsif groups_complete
            steps << StageWizardStep.new(stage_permalink)
          end
          steps
        end

        def is_all_groups_predicted?
          (not self.next_step or (self.next_step.length > 1))
        end

        def stage_permalink
          self.next_step ? self.next_step : self.current_step
        end
      end
    end
  end
end
