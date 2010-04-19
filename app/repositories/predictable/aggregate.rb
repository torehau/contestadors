module Predictable
  class Aggregate
    attr_accessor :root, :validation_errors, :default_error_msg, :state

    def initialize(aggregate_root_id=nil, contest=nil)
      if aggregate_root_id
        @root = get_aggregate_root(aggregate_root_id)
        @builder = get_aggregate_root_builder(aggregate_root_id)
      end
      @validation_errors = {}
      @contest = contest
      @state = "unpredicted"
    end

    def set_existing_predictions(user)
      @user = user
      @existing_predictions = @builder.build_from_existing(@user)

      if @existing_predictions
        @root = @existing_predictions
        self.predict!
      end
    end

    def set_new_predictions(new_predictions, user)
      @new_predictions = get_new_predictions(new_predictions)
      @root = @new_predictions
      self.predict!
      @user = user
      self.user_not_set! unless @user
    end

    def validate
      @validation_errors = validate_new_predictions
      self.invalidate! unless @validation_errors.empty?
    end
    
    def has_validation_errors?
      (@validation_errors and @validation_errors.size > 0)
    end

    def has_validation_error_for?(predictable_id)
      (has_validation_errors? and @validation_errors.has_key?(predictable_id))
    end

    def save
      set_update_mode_if_existing_predictions

      begin
        Prediction.transaction do
          save_new_aggregate_predictions
          self.saved!
        end
      rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid
        self.db_orm_exception!
      end
    end

    def is_new_predictions?
      @new_predictions and not has_existing_predictions?
    end

    def has_existing_predictions?
      (@existing_predictions and not @existing_predictions.empty?) == true
    end

    def redirect_on_save?
      false
    end

    def root_id
      raise 'Abstract method. Must be defined in concrete subclass.'
    end

  protected

    def get_aggregate_root(aggregate_root_id)
      raise 'Abstract method. Must be defined in concrete subclass.'
    end

    def get_aggregate_root_builder(aggregate_root_id)
      raise 'Abstract method. Must be defined in concrete subclass.'
    end

    def get_new_predictions(new_predictions)
      @builder.build_from_new(new_predictions)
    end

    def validate_new_predictions
      {}
    end
    
    def get_existing_predictions
      raise 'Abstract method. Must be defined in concrete subclass.'
    end

    def invalidates_dependant_aggregates?
      raise 'Abstract method. Must be defined in concrete subclass.'
    end
    
    def save_new_aggregate_predictions
      raise 'Abstract method. Must be defined in concrete subclass.'
    end

    def notify
      raise 'Abstract method. Must be defined in concrete subclass.'
    end

    def summary
      @summary ||= @user.summary_of(@contest)
    end

    # returns a hash for the predictables keyed by the corresponding ids
    def predictables_by_id(predictables)
      Hash[*(predictables).collect{|predictable| [predictable.id, predictable]}.flatten]
    end

    def set_update_mode_if_existing_predictions
      @existing_predictions = get_existing_predictions

      if has_existing_predictions?
        self.update_existing!

        if invalidates_dependant_aggregates?
          self.invalidate_dependant_aggregates!
        end
      end
    end

    state_machine :initial => :unpredicted do
      after_transition [:predicted, :update_with_invalidations] => :saved_ok, :do => :notify

      event :predict do
        transition :unpredicted => :predicted
      end

      event :user_not_set do
        transition :predicted => :no_user
      end

      event :invalidate do
        transition [:predicted, :no_user] => :invalid
      end

      event :update_existing do
        transition :predicted => :update
      end

      event :invalidate_dependant_aggregates do
        transition :update => :update_with_invalidations
      end

      event :saved do
        transition [:predicted, :update, :update_with_invalidations] => :saved_ok
      end

      event :db_orm_exception do
        transition [:predicted, :update, :update_with_invalidations] => :failed
      end
    end
  end
end
