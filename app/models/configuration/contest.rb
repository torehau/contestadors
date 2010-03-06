module Configuration
  class Contest < ActiveRecord::Base
    set_table_name "configuration_contests"    
    has_many :included_sets, :class_name => "Configuration::IncludedSet", :foreign_key => "configuration_contest_id"
    has_many :sets, :through => :included_sets, :class_name => "Configuration::Set"
    has_many :prediction_summaries, :class_name => "Prediction::Summary", :foreign_key => "prediction_summary_id"

    def self.all_available
      now = Time.now
      find(:all, :conditions => ["available_from <= ? and participation_ends_at >= ?", now, now])
    end
  end
end
