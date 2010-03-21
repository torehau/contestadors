module Predictable
  class WizardStep

    attr_accessor :label, :type, :id

    def initialize(label, type, id)
      @label = label
      @type = type
      @id = id
    end
  end
end
