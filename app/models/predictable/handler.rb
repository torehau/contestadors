module Predictable
  module Handler
    attr_accessor :objectives
    attr_accessor :objectives_meet

    def resolve_objectives_for(prediction, objectives)
      raise "Abstract method. Must be implemted by including class."
    end

    def total_possible_points
      tpp = 0
      @objectives.each{|o| tpp += o.possible_points}
      tpp
    end
  end
end
