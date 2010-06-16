module Predictable
  module Handler
    attr_accessor :objectives_meet

    def resolve_objectives_for(prediction, objectives)
      raise "Abstract method. Must be implemted by including class."
    end
  end
end
