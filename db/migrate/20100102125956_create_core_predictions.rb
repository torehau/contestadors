class CreateCorePredictions < ActiveRecord::Migration
  def self.up
    create_table :core_predictions do |t|
      t.integer :core_user_id
      t.integer :configuration_predictable_item_id
      t.string :predicted_value

      t.timestamps
    end

    add_index :core_predictions, :core_user_id
    add_index :core_predictions, :configuration_predictable_item_id
  end

  def self.down
    drop_table :core_predictions
  end
end
