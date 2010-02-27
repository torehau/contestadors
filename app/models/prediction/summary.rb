module Prediction
  class Summary < ActiveRecord::Base
    set_table_name("prediction_summaries")
    belongs_to :user, :class_name => "Core::User", :foreign_key => 'core_user_id'
    has_many :predictions, :through => :user

    # wizard support accessors:
    attr_accessor :current_step, :next_step, :all_available_steps

    def after_initialize
      update_wizard_accessors
    end

    state_machine :initial => :i do

      after_transition [:r, :q, :s, :fi, :t] => :h, :do => :delete_knockout_stage_predictions

      from_state = :i

      ('a'..'h').each do |group_name|
        event_name = ('predict_group_' + group_name).to_sym
        to_state = group_name.to_sym

        event event_name do
          transition from_state => to_state, [:r, :q, :s, :fi, :t] => :h
        end
        from_state = to_state
      end

      event :predict_round_of_16 do
        transition :h => :r
      end

      event :predict_quarter_finals do
        transition :r => :q
      end

      event :predict_semi_finals do
        transition :q => :s
      end

      event :predict_final do
        transition :s => :fi
      end

      event :predict_third_place do
        transition :fi => :t
      end

    end

    def predict_group(name)
      puts "predict group " + name
      send(('predict_group_' + name.downcase).to_sym)
      update_wizard_accessors
    end

    def predict_stage(description)
      send(('predict_' + description.gsub(/ /, '_').downcase).to_sym)
      update_wizard_accessors
    end

    def url_params
      aggregate_root_type, aggregate_root_id = "group", "A"

      if ('a'..'h') === current_step
        aggregate_root_id = current_step.upcase
      end
      {:aggregate_root_type => aggregate_root_type, :aggregate_root_id => aggregate_root_id}
    end

    private

    CURRENT_TO_NET_KNOCKOUT_STATE = {'h' => 'r',
                                     'r' => 'q',
                                     'q' => 's',
                                     's' => 'f',
                                     'f' => 't'}

    def update_wizard_accessors
      self.current_step = state
      self.next_step = get_next_step
      self.all_available_steps = get_all_available_steps
    end

    def get_next_step
      return 'a' if state.eql?('i')
      return state.succ if ('a'..'g') === state
      CURRENT_TO_NET_KNOCKOUT_STATE[state]
    end

    def get_all_available_steps
      steps = {:group => [], :stage => []}

      if 'i'.eql?(state)
        steps[:group] << 'a'
      elsif ('a'..'g') === state
        ('a'..state.succ).each{|step| steps[:group] << step}
      else
        ('a'..'h').each{|step| steps[:group] << step}

        if 'h'.eql?(state)
          steps[:stage] << 'r'
        elsif 'r'.eql?(state)
          steps[:stage].concat(['r', 'q'])
        elsif 'q'.eql?(state)
          steps[:stage].concat(['r', 'q', 's'])
        else
          steps[:stage].concat(['r', 'q', 's', 'f', 't'])
        end
      end
      steps
    end

    GROUPS_AND_ROUND_OF_16_COMPLETED = 77

    # any prediction for knockout stages should be invalidated if changing predictions
    # for groups after having started predicting the knockout stages
    def delete_knockout_stage_predictions
      items = get_predictable_items_for_explicit_predicted_knockout_stages
      ActiveRecord::Base.transaction do
        Prediction::Base.delete_all(["core_user_id = ? and configuration_predictable_item_id in (?)", user.id, items])
        self.percentage_completed = GROUPS_AND_ROUND_OF_16_COMPLETED
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