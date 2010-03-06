module Prediction
  class Summary < ActiveRecord::Base
    set_table_name("prediction_summaries")
    belongs_to :user, :class_name => "Core::User", :foreign_key => 'core_user_id'
    belongs_to :contest, :class_name => "Configuration::Contest", :foreign_key => 'configuration_contest_id'
    has_many :predictions, :through => :user

    # wizard helpers
    attr_accessor :current_step, :next_step, :all_available_steps

    def after_initialize
      update_wizard
    end

    PROGRESS_WHEN_GROUPS_AND_ROUND_OF_16_PREDICTED  = 77
    LAST_GROUP_ID                                   = 'h'
    KNOCKOUT_STAGES                                 = [:r, :q, :s, :fi, :t]
    KNOCKOUT_STAGE_ID_BY_STATE_NAME                 = {'r'  => 'round-of-16',
                                                       'q'  => 'quarter-finals',
                                                       's'  => 'semi-finals',
                                                       'fi' => 'final',
                                                       't'  => 'third-place'}

    state_machine :initial => :i do
      
      after_transition KNOCKOUT_STAGES => :h, :do => :delete_knockout_stage_predictions
      after_transition any => any, :do => :update_wizard
      
      from_state = :i

      ('a'..'h').each do |group_name|
        event_name = ('predict_group_' + group_name).to_sym
        to_state = group_name.to_sym

        event event_name do
          transition from_state => to_state, KNOCKOUT_STAGES => :h
        end
        from_state = to_state
      end

      KNOCKOUT_STAGES.each do |to_state|
        event_name = ('predict_' + KNOCKOUT_STAGE_ID_BY_STATE_NAME[to_state.to_s].gsub('-','_')).to_sym
        
        event event_name do
          transition from_state => to_state
        end
        from_state = to_state
      end
      
    end

    def predict_group(name)
      send(('predict_group_' + name.downcase).to_sym)
    end

    def predict_stage(description)
      send(('predict_' + description.gsub(/ /, '_').downcase).to_sym)
    end

  private

    def update_wizard
      self.current_step = convert_to_wizard_step_id(state)
      self.next_step = convert_to_wizard_step_id(get_next_possible_advanced_state)
      self.all_available_steps = collect_available_steps
    end

    def convert_to_wizard_step_id(state_name)
      return state_name unless KNOCKOUT_STAGE_ID_BY_STATE_NAME.has_key?(state_name)
      KNOCKOUT_STAGE_ID_BY_STATE_NAME[state_name]
    end

    def get_next_possible_advanced_state
      next_possible_state = nil
      possible_transitions = state_transitions

      if possible_transitions.size == 1
        next_possible_state = possible_transitions.first.to
      elsif possible_transitions.size > 1
        knockout_stage_transitions = possible_transitions.select{|pt| not pt.event.to_s.include?("predict_group")}
        next_possible_state = knockout_stage_transitions.empty? ? nil : knockout_stage_transitions.first.to
      end
      next_possible_state
    end

    def collect_available_steps
      steps = []
      last_available_group = is_all_groups_predicted? ? LAST_GROUP_ID : self.next_step
      ('a'..last_available_group).each{|group_name| steps << GroupWizardStep.new(group_name)}
      steps << StageWizardStep.new(stage_permalink) if is_all_groups_predicted?
      steps
    end

    def is_all_groups_predicted?
      (KNOCKOUT_STAGE_ID_BY_STATE_NAME.has_value?(self.next_step) or not self.next_step)
    end

    def stage_permalink
      self.next_step ? self.next_step : self.current_step
    end
        
    # any prediction for knockout stages should be invalidated if changing predictions
    # for groups after having started predicting the knockout stages
    def delete_knockout_stage_predictions
      items = get_predictable_items_for_predictions_to_delete
      
      ActiveRecord::Base.transaction do
        Prediction::Base.delete_all(["core_user_id = ? and configuration_predictable_item_id in (?)", user.id, items])
        self.percentage_completed = PROGRESS_WHEN_GROUPS_AND_ROUND_OF_16_PREDICTED
        self.save!
      end
    end

    def get_predictable_items_for_predictions_to_delete
      items = []
      Predictable::Championship::Stage.explicit_predicted_knockout_stages.each do |stage|
        set = Configuration::Set.find_by_description "Teams through to #{stage.description}"
        set.predictable_items.each {|item| items << item.id}
      end
      set = Configuration::Set.find_by_description "Third Place Team"
      items << set.predictable_items.first.id
      set = Configuration::Set.find_by_description "Winner Team"
      items << set.predictable_items.first.id
      items
    end
  end
end