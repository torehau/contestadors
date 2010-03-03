module Prediction
  class Summary < ActiveRecord::Base
    set_table_name("prediction_summaries")
    belongs_to :user, :class_name => "Core::User", :foreign_key => 'core_user_id'
    has_many :predictions, :through => :user

    # wizard helpers
    attr_accessor :current_step, :next_step
    attr_accessor :groups_available_for_prediction, :is_knockout_stages_available_for_prediction
    alias_method :is_knockout_stages_available_for_prediction?, :is_knockout_stages_available_for_prediction


    def after_initialize
      update_wizard
    end

    PROGRESS_WHEN_GROUPS_AND_ROUND_OF_16_PREDICTED  = 77
    KNOCKOUT_STAGES                                 = [:r, :q, :s, :fi, :t]
    KNOCKOUT_STAGE_ID_BY_STATE_NAME                 = {'r'  => 'round-of-16',
                                                       'q'  => 'quarter-finals',
                                                       's'  => 'semi-finals',
                                                       'fi' => 'final',
                                                       't'  => 'third-place'}

    state_machine :initial => :i do

      after_transition any => any, :do => :update_wizard
      after_transition KNOCKOUT_STAGES => :h, :do => :delete_knockout_stage_predictions
      
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
      self.groups_available_for_prediction = []
      last_available_group = ('a'..'h') === self.next_step ? self.next_step : 'h'
      ('a'..last_available_group).each{|group_name| self.groups_available_for_prediction << group_name}
      self.is_knockout_stages_available_for_prediction = (not (('a'..'h') === self.next_step))
    end

    def get_next_possible_advanced_state
      next_possible_state = nil
      possible_transitions = state_transitions

      if possible_transitions.size == 1
        next_possible_state = possible_transitions.first.to
      elsif possible_transitions.size > 1
        next_possible_state = possible_transitions.select{|pt| not pt.event.to_s.include?("predict_group")}.first.to
      end
      next_possible_state
    end

    def convert_to_wizard_step_id(state_name)
      return state_name unless KNOCKOUT_STAGE_ID_BY_STATE_NAME.has_key?(state_name)
      KNOCKOUT_STAGE_ID_BY_STATE_NAME[state_name]
    end        

    # any prediction for knockout stages should be invalidated if changing predictions
    # for groups after having started predicting the knockout stages
    def delete_knockout_stage_predictions
      items = get_predictable_items_for_explicit_predicted_knockout_stages
      ActiveRecord::Base.transaction do
        Prediction::Base.delete_all(["core_user_id = ? and configuration_predictable_item_id in (?)", user.id, items])
        self.percentage_completed = PROGRESS_WHEN_GROUPS_AND_ROUND_OF_16_PREDICTED
        self.save!
      end
    end

    def get_predictable_items_for_explicit_predicted_knockout_stages
      items = []
      Predictable::Championship::Stage.explicit_predicted_knockout_stages.each do |stage|
        set = Configuration::Set.find_by_description "Teams through to #{stage.description}"
        set.predictable_items.each {|item| items << item.id}
      end
      items
    end
  end
end