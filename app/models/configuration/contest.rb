module Configuration
  class Contest < ActiveRecord::Base
    set_table_name "configuration_contests"    
    has_many :included_sets, :class_name => "Configuration::IncludedSet", :foreign_key => "configuration_contest_id"
    has_many :sets, :through => :included_sets, :class_name => "Configuration::Set"
    has_many :prediction_states, :class_name => "Configuration::PredictionState", :foreign_key => "configuration_contest_id" do
      def by_state_name(state_name)
        find(:first, :conditions => {:state_name => state_name})
      end
      def by_aggregate_root(aggregate_root_type, permalink)
        find(:first, :conditions => {:aggregate_root_type => aggregate_root_type, :permalink => permalink})
      end
    end
    has_many :prediction_summaries
    has_many :contest_instances, :foreign_key => "configuration_contest_id"
    has_many :invitations, :through => :contest_instances

    def self.all_available
      now = Time.now
      find(:all, :conditions => ["available_from <= ? and participation_ends_at >= ?", now, now])
    end

    def self.from_permalink_or_first_available(permalink)
      contest = self.where(:permalink => permalink).last#find_by_permalink(permalink)
      contest ||= self.all_available.first
    end

    def set(description)
      self.sets.where(:description => description).first
    end

    def prediction_state(state_name)
      self.prediction_states.by_state_name(state_name)
    end

    #def last_prediction_state
    #  self.prediction_states.where(:next_state_name => nil).first
    #end

    def first_prediction_state(aggregate_root_type)
      first_state = self.prediction_states.where(:aggregate_root_type => aggregate_root_type).first
      first_state.state_name == "i" ? first_state.next : first_state
    end

    def last_prediction_state(aggregate_root_type)
      self.prediction_states.where(:aggregate_root_type => aggregate_root_type).last
    end

    def prediction_state_by_aggregate_root(aggregate_root_type, aggregate_root_id)
      prediction_states.by_aggregate_root(aggregate_root_type, aggregate_root_id)
    end

    def unique_aggregate_root_ids(aggregate_root_type)
      prediction_states.where(:aggregate_root_type => aggregate_root_type).collect {|state| state.aggregate_root_id}.uniq
    end

    def wizard_module
      @wizard_module ||= get_wizard_module
    end

    def repository(aggregate_root_type, user)
      @repository_factory ||= get_repository_factory
      @repository_factory.create(aggregate_root_type, self, user)
    end

    def delete_invalidated_predictions(user)
      resolver_type = get_invalidated_predictions_resolver
      items = resolver_type.new(user, self).get_predictable_items_for_invalidated_predictions
      @repository_factory ||= get_repository_factory
      repository = @repository_factory.create
      repository.delete(items, user)
    end

    def update_all_score_tables
      self.contest_instances.each {|instance| instance.update_score_table_positions}
    end

  private

    # TODO the following methods handles a separate concern and should be moved to a dedicated module
    #      e.g., PredictableContextTypeDeterminator

    def get_wizard_module
      get_type_in_predictable_module("Wizard", Module)
    end

    def get_repository_factory
      get_type_in_predictable_module("RepositoryFactory", Object)
    end

    def get_invalidated_predictions_resolver
      get_type_in_predictable_module("InvalidatedPredictionsResolver", Object)
    end

    def get_type_in_predictable_module(type_name, type_entity)
      complete_type_name = "Predictable::" + self.predictable_module + "::" + type_name
      complete_type_name.split("::").inject(type_entity) {|x, y| x.const_get(y)}
    end
  end
end
