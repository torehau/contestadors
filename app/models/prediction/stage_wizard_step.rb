module Prediction
  class StageWizardStep < WizardStep
    def initialize(stage_permalink)
      super("Knockout Stages", "stage", stage_permalink)
    end
  end
end
