class PredictionSummary < ActiveRecord::Base
  after_create :update_map_and_init_high_score_table_position
  belongs_to :user
  belongs_to :contest, :class_name => "Configuration::Contest", :foreign_key => 'configuration_contest_id'
  has_many :predictions, :through => :user
  has_many :score_table_positions
  has_one :high_score_list_position

  KNOCKOUT_STAGES                                 = [:r, :q, :s, :fi]
  KNOCKOUT_STAGE_ID_BY_STATE_NAME                 = {'r'  => 'round-of-16',
                                                     'q'  => 'quarter-finals',
                                                     's'  => 'semi-finals',
                                                     'fi' => 'final'}

  state_machine :initial => :i do

    after_transition any => :f, :do => :resolve_four_best_third_placed_teams
    after_transition KNOCKOUT_STAGES => :f,
                     [:q, :s, :fi] => :r,
                     [:s, :fi] => [:r, :q],
                     [:fi] => [:r, :q, :s], :do => :delete_invalidated_predictions
    after_transition any => any - :fi, :do => :update_wizard
    after_transition any => any, :do => :update_map

    from_state = :i

    ('a'..'f').each do |group_name|
      event_name = ('predict_group_' + group_name).to_sym
      to_state = group_name.to_sym

      event event_name do
        transition from_state => to_state, KNOCKOUT_STAGES => :f
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

  def setup_wizard(aggregate_root_type, aggregate_root_id)
    extend contest.wizard_module::InstanceMethods
    update_wizard(aggregate_root_type, aggregate_root_id)
  end

  def predict_group(name)
    extend contest.wizard_module::InstanceMethods
    send(('predict_group_' + name.downcase).to_sym)
  end

  def predict_stage(description)
    extend contest.wizard_module::InstanceMethods
    send(('predict_' + description.gsub(/ /, '_').downcase).to_sym)
  end

  def update_score_and_map_values(points_to_add, points_to_reduce_from_map)
    previous_score, previous_map = self.total_score, self.map
    updated_score = self.total_score + points_to_add
    updated_map = self.map - points_to_reduce_from_map
    self.update_attributes(:previous_score => previous_score, :previous_map => previous_map, :total_score => updated_score, :map => updated_map)
    self.save!
  end
  
  def has_predictions
    self.state != 'i'
  end
  

private

  # for deleting any predictions invalidated by a state transition
  def delete_invalidated_predictions
    contest.delete_invalidated_predictions(user)
  end
  
  def update_map_and_init_high_score_table_position
    update_map
    init_high_score_table_position
  end

  def update_map
    #prediction_state = Configuration::PredictionState.find_by_state_name(self.state)
    prediction_state = Configuration::PredictionState.where(:configuration_contest_id => self.contest.id, :state_name => self.state).first
    self.map = prediction_state.points_accumulated
    self.save!
  end
  
  def init_high_score_table_position
    HighScoreListPosition.create!(:prediction_summary_id => self.id,
	       						 :configuration_contest_id => self.contest.id,
			    				 :user_id => self.user.id,
				    			 :has_predictions => self.state != 'i',
					    		 :position => 1)  
  end

  def resolve_four_best_third_placed_teams
    third_placed_stage_teams_predictions = Predictable::Championship.BestThirdPlacedStageTeamsPredictionsResolver.new(this.contest, this.user)
  end
end
