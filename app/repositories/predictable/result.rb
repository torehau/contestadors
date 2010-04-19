module Predictable
  class Result
    attr_accessor :aggregates, :current, :validation_errors, :all_roots

    def initialize(current, predicted={}, unpredicted={}, invalidated={})
      @current = current
      @aggregates = {:current => @current, :predicted => predicted, :unpredicted => unpredicted, :invalidated => invalidated}
      @validation_errors = @current.validation_errors
    end

    def aggregates_associated(key, value)
      @aggregates[key] = value
    end
  end
end
