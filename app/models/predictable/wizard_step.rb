module Predictable
  class WizardStep

    attr_accessor :label, :type, :id

    def initialize(label, type, id)
      @label = label
      @type = type
      @id = id
    end

    # specifies the condition(s) for highlighting the wizard step menu item.
    def highlight_conditions
      {:aggregate_root_id => @id}
    end
  end
end
