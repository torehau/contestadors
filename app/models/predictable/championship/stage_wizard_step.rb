module Predictable
  module Championship
    class StageWizardStep < Predictable::WizardStep
      def initialize(stage_permalink)
        super("Knockout Stages", "stage", stage_permalink)
      end
    end
  end
end