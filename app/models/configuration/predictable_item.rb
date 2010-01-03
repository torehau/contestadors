module Configuration
  class PredictableItem < ActiveRecord::Base
    set_table_name("configuration_predictable_items")
    belongs_to :set, :class_name => "Configuration::Set", :foreign_key => 'configuration_set_id'
    has_many :predictions, :class_name => "Core::Prediction", :foreign_key => "configuration_predictable_item_id"

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
