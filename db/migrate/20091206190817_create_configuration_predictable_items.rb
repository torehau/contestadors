class CreateConfigurationPredictableItems < ActiveRecord::Migration
  def self.up
    create_table :configuration_predictable_items do |t|
      t.integer :configuration_set_id
      t.integer :predictable_id

      t.timestamps
    end
  end

  def self.down
    drop_table :configuration_predictable_items
  end
end
