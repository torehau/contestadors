module Predictable
  module Championship
    module Wizard
      module InstanceMethods

        attr_accessor :current_step, :next_step, :all_available_steps, :prediction_progress

        def is_completed?
          'completed'.eql?(self.current_step)
        end

        def update_wizard
          current_prediction_state = contest.prediction_state(state)
          self.prediction_progress = current_prediction_state.progress_accumulated
          self.current_step = current_prediction_state.permalink
          next_prediction_state = current_prediction_state.next
          self.next_step = next_prediction_state ? next_prediction_state.permalink : nil
          self.all_available_steps = collect_available_steps
        end

        def collect_available_steps
          steps = []
          last_available_group = is_all_groups_predicted? ? 'h' : self.next_step
          ('a'..last_available_group).each{|group_name| steps << GroupWizardStep.new(group_name)}
          steps << StageWizardStep.new(stage_permalink) if is_all_groups_predicted?
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
