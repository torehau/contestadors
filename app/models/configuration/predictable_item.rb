module Configuration
  class PredictableItem < ActiveRecord::Base
    set_table_name("configuration_predictable_items")
    belongs_to :set, :class_name => "Configuration::Set", :foreign_key => 'configuration_set_id'
    has_many :predictions, :class_name => "Prediction", :foreign_key => "configuration_predictable_item_id"

    delegate :description, :to => :set

    # returns the proxied object instance if the predictable_id is different from 0,
    # otherwise all instances of the predictable type is returned
    def predictable
      pred_type = set.predictable_type
      klass = pred_type.split("::").inject(Object) {|x, y| x.const_get(y)}
      if predictable_id
        return klass.find(predictable_id)
      else
        return klass.find(:all)
      end
    end

    def predictable_table
      snakecase(set.predictable_type.pluralize)
    end

    def settle_predictions_for(predictable)
      self.settle!
      objectives = self.set.objectives

      self.predictions.each do |prediction|
        compare_result = predictable.resolve_objectives_for(prediction, objectives)
        score, map_reduction, objectives_meet = 0, 0, compare_result[:objectives_meet].size
        compare_result[:objectives_meet].each {|objective| score += objective.possible_points}
        compare_result[:objectives_missed].each {|objective| map_reduction += objective.possible_points}
        prediction.update_attributes(:received_points => score, :objectives_meet => objectives_meet)
        prediction.save!
        yield(prediction.user, score, map_reduction)
      end
      self.complete!
    end

    def self.settle_predictions_for(items, dependant_items_by_item_id, points_giving_value, map_reduction_value)
      items_by_actual_values = {}
      items.each do |item|
        item.settle!
        actual_value = item.predictable.predictable_field_value
        items_by_actual_values[actual_value] = item if actual_value
      end

      User.find(:all).each do |user|
        score, map_reduction = 0, 0

        user.predictions_for_subset(items).each do |prediction|
           received_points, objectives_meet = 0, 0

          if items_by_actual_values.keys.include?(prediction.predicted_value)
            item = items_by_actual_values[prediction.predicted_value]
            item.set.objectives.each do |objective|
              objectives_meet += 1
              received_points += objective.possible_points
              score += received_points
            end            
          else
            item = prediction.predictable_item
            item.set.objectives.each {|objective| map_reduction += objective.possible_points}

            user.predictions_for_subset(dependant_items_by_item_id[item.id]).each do |dependant_prediction|
              
              if dependant_prediction.predicted_value.eql?(prediction.predicted_value)
                dependant_item = dependant_prediction.predictable_item
                dependant_item.set.objectives.each {|objective| map_reduction += objective.possible_points}
                dependant_prediction.update_attributes(:received_points => 0, :objectives_meet => 0)
                dependant_prediction.save!
              end
            end
          end
          prediction.update_attributes(:received_points => received_points, :objectives_meet => objectives_meet)
          prediction.save!
        end
        yield(user, score, map_reduction)        
      end
      
      items.each {|item| item.complete!}
    end

    state_machine :initial => :unsettled do

      event :settle do
        transition :unsettled => :settled
      end

      event :complete do
        transition :settled => :processed
      end

    end

    private

    def snakecase(camel_cased_word)
      camel_cased_word.to_s.gsub(/::/, '_').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end
  end
end
