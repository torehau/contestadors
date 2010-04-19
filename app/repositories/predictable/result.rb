module Predictable
  class Result
    attr_accessor :aggregates, :current, :validation_errors, :wizard_hint, :all_roots# :state

    def initialize(current, predicted={}, unpredicted={}, invalidated={})#, validation_errors={})
      @current = current
      @aggregates = {:current => @current, :predicted => predicted, :unpredicted => unpredicted, :invalidated => invalidated}
      @validation_errors = @current.validation_errors
    end

    def aggregates_associated(key, value)
      @aggregates[key] = value
    end

#    def all_roots
#      (@aggregates[:predicted].merge(@aggregates[:unpredicted])).values
#    end
  end
end
