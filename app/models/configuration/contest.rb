module Configuration
  class Contest < ActiveRecord::Base
    set_table_name "configuration_contests"    
    has_many :included_sets, :class_name => "Configuration::IncludedSet", :foreign_key => "configuration_contest_id"
    has_many :sets, :through => :included_sets, :class_name => "Configuration::Set"
    has_many :prediction_states, :class_name => "Configuration::PredictionState", :foreign_key => "configuration_contest_id" do
      def by_state_name(state_name)
        find(:first, :conditions => {:state_name => state_name})
      end
    end
    has_many :prediction_summaries

    def self.all_available
      now = Time.now
      find(:all, :conditions => ["available_from <= ? and participation_ends_at >= ?", now, now])
    end

    def prediction_state(state_name)
      prediction_states.by_state_name(state_name)
    end

    def wizard_module
      @wizard_module ||= get_wizard_module
    end

    def repository(user, params)
      @aggregate_type ||= get_aggregate_type
      aggregate = @aggregate_type.new(user, params)
      @repository_factory ||= get_repository_factory
      @repository_factory.create(aggregate)
    end

    def delete_invalidated_predictions(user)
      resolver_type = get_invalidated_predictions_resolver
      items = resolver_type.new(user, self).get_predictable_items_for_invalidated_predictions
      @repository_factory ||= get_repository_factory
      repository = @repository_factory.create
      repository.delete(items, user)
    end

  private

    def get_wizard_module
      wizard_type = "Predictable::" + self.predictable_module + "::Wizard"
      wizard_type.split("::").inject(Module) {|x, y| x.const_get(y)}
    end

    def get_repository_factory
      repository_factory_type = "Predictable::" + self.predictable_module + "::RepositoryFactory"
      repository_factory_type.split("::").inject(Object) {|x, y| x.const_get(y)}
    end

    def get_aggregate_type
      aggregate_type = "Predictable::" + self.predictable_module + "::Aggregate"
      aggregate_type.split("::").inject(Object) {|x, y| x.const_get(y)}
    end

    def get_invalidated_predictions_resolver
      resolver_type = "Predictable::" + self.predictable_module + "::InvalidatedPredictionsResolver"
      resolver_type.split("::").inject(Object) {|x, y| x.const_get(y)}
    end
  end
end
