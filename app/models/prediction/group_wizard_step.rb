module Prediction
  class GroupWizardStep < WizardStep

    def initialize(group)
      group_name = group.upcase
      label = "Group " + group_name
      super(label, "group", group_name)
    end
  end
end
