module Configuration
  class PredictionState < ActiveRecord::Base
    set_table_name("configuration_prediction_states")
    belongs_to :contest, :class_name => "Configuration::Contest", :foreign_key => 'configuration_contest_id'
    has_many :sets, :class_name => "Configuration::Set", :foreign_key => "configuration_prediction_state_id"

    def next
      PredictionState.find(:first, :conditions => {:state_name => next_state_name})
    end
  end
end
