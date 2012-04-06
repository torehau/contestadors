module Configuration
  class PredictionState < ActiveRecord::Base
    set_table_name("configuration_prediction_states")
    belongs_to :contest, :class_name => "Configuration::Contest", :foreign_key => 'configuration_contest_id'
    has_many :sets, :class_name => "Configuration::Set", :foreign_key => "configuration_prediction_state_id"

    def next
      PredictionState.where(:state_name => self.next_state_name, :configuration_contest_id => self.contest.id).first
    end

    def is_before?(other_state)
      return false unless other_state
      self.position < other_state.position
    end

    def request_params
      {:contest => self.contest.permalink, :aggregate_root_type => self.aggregate_root_type, :aggregate_root_id => self.permalink}
    end
  end
end
