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

    LAST_GROUP_ID                                   = 'h'
    KNOCKOUT_STAGES                                 = [:r, :q, :s, :fi, :t]
    KNOCKOUT_STAGE_ID_BY_STATE_NAME                 = {'r'  => 'round-of-16',
                                                       'q'  => 'quarter-finals',
                                                       's'  => 'semi-finals',
                                                       'fi' => 'final',
                                                       't'  => 'third-place'}
    PERCENTAGE_COMPLETED_BY_STATE_NAME              = {'h'  => 77,
                                                       'r'  => 82,
                                                       'q'  => 88,
                                                       's'  => 92,
                                                       'fi' => 97,
                                                       't'  => 100}

    state_machine :initial => :i do
      
      after_transition KNOCKOUT_STAGES => :h,
                       [:q, :s, :fi, :t] => :r,
                       [:s, :fi, :t] => [:r, :q],
                       [:t] => [:r, :q, :s], :do => :delete_knockout_stage_predictions
      after_transition any => any - :fi, :do => :update_wizard
      
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
          transition from_state => to_state, KNOCKOUT_STAGES => to_state
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

    def is_completed?
      'completed'.eql?(self.current_step)
    end

  private

    def update_wizard
      self.current_step = convert_to_wizard_step_id(state)

      if 'third-place'.eql?(self.current_step)
        self.current_step = 'completed'
        self.next_step = nil
      else
        self.next_step = get_next_possible_advanced_state
      end
      self.all_available_steps = collect_available_steps
    end

    def convert_to_wizard_step_id(state_name)
      return state_name unless KNOCKOUT_STAGE_ID_BY_STATE_NAME.has_key?(state_name)
      KNOCKOUT_STAGE_ID_BY_STATE_NAME[state_name]
    end

    def get_next_possible_advanced_state
      next_possible_state = nil

      if 'i'.eql?(self.current_step)
        next_possible_state = 'a'
      elsif %w{a b c d e f g}.include?(self.current_step)
        next_possible_state = self.current_step.succ
      elsif 'h'.eql?(self.current_step)
        next_possible_state = 'round-of-16'
      else
        next_stage = Predictable::Championship::Stage.from_permalink(self.current_step).next
        next_possible_state = next_stage ? next_stage.permalink : nil
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

      unless items.empty?
        ActiveRecord::Base.transaction do
          Prediction::Base.delete_all(["core_user_id = ? and configuration_predictable_item_id in (?)", user.id, items])
          self.percentage_completed = PERCENTAGE_COMPLETED_BY_STATE_NAME[state]
          self.save!
        end
      end
    end

    def get_predictable_items_for_predictions_to_delete
      items = []
      stages = get_stages_to_delete_predictions_for
      return items if stages.empty?

      stages.each do |stage|
        set = Configuration::Set.find_by_description "Teams through to #{stage.description}"
        set.predictable_items.each {|item| items << item.id} if set
      end
      set = Configuration::Set.find_by_description "Third Place Team"
      items << set.predictable_items.first.id
      set = Configuration::Set.find_by_description "Winner Team"
      items << set.predictable_items.first.id
      items
    end

    def get_stages_to_delete_predictions_for
      stages_predicted_explicitly = Predictable::Championship::Stage.explicit_predicted_knockout_stages
      return stages_predicted_explicitly unless KNOCKOUT_STAGE_ID_BY_STATE_NAME.has_key?(state)
      current_stage = Predictable::Championship::Stage.from_permalink(KNOCKOUT_STAGE_ID_BY_STATE_NAME[state])
      next_stage = current_stage.next
      stages = []
      while next_stage.next do
        stages << next_stage.next
        next_stage = next_stage.next
      end
      stages
    end
  end
end