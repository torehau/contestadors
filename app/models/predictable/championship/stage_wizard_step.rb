module Predictable
  module Championship
    class StageWizardStep < Predictable::WizardStep
      def initialize(stage_permalink)
        super("Knockout Stages", "stage", stage_permalink)
      end

      def highlight_conditions
        {:aggregate_root_type => @type}
      end
    end
  end
end