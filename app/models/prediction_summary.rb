class PredictionSummary < ActiveRecord::Base
  after_create :update_map
  belongs_to :user
  belongs_to :contest, :class_name => "Configuration::Contest", :foreign_key => 'configuration_contest_id'
  has_many :predictions, :through => :user
  has_many :score_table_positions

  KNOCKOUT_STAGES                                 = [:r, :q, :s, :fi, :t]
  KNOCKOUT_STAGE_ID_BY_STATE_NAME                 = {'r'  => 'round-of-16',
                                                     'q'  => 'quarter-finals',
                                                     's'  => 'semi-finals',
                                                     'fi' => 'final',
                                                     't'  => 'third-place'}

  state_machine :initial => :i do

    after_transition KNOCKOUT_STAGES => :h,
                     [:q, :s, :fi, :t] => :r,
                     [:s, :fi, :t] => [:r, :q],
                     [:t] => [:r, :q, :s], :do => :delete_invalidated_predictions
    after_transition any => any - :fi, :do => :update_wizard
    after_transition any => any, :do => :update_map

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

private

  # for deleting any predictions invalidated by a state transition
  def delete_invalidated_predictions
    contest.delete_invalidated_predictions(user)
  end

  def update_map
    #prediction_state = Configuration::PredictionState.find_by_state_name(self.state)
    prediction_state = Configuration::PredictionState.where(:configuration_contest_id => self.contest.id, :state_name => self.state).first
    self.map = prediction_state.points_accumulated
    self.save!
  end
end
