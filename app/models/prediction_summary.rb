class PredictionSummary < ActiveRecord::Base
  belongs_to :user
  belongs_to :contest, :class_name => "Configuration::Contest", :foreign_key => 'configuration_contest_id'
  has_many :predictions, :through => :user

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

  def setup_wizard
    extend contest.wizard_module::InstanceMethods
    update_wizard
  end

  def predict_group(name)
    extend contest.wizard_module::InstanceMethods
    send(('predict_group_' + name.downcase).to_sym)
  end

  def predict_stage(description)
    extend contest.wizard_module::InstanceMethods
    send(('predict_' + description.gsub(/ /, '_').downcase).to_sym)
  end

private

  # for deleting any predictions invalidated by a state transiction
  def delete_invalidated_predictions
    contest.delete_invalidated_predictions(user)
  end
end
