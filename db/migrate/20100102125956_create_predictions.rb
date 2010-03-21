class CreatePredictions < ActiveRecord::Migration
  def self.up
    create_table :predictions do |t|
      t.integer :user_id
      t.integer :configuration_predictable_item_id
      t.string :predicted_value

      t.timestamps
    end

    add_index :predictions, :user_id
    add_index :predictions, :configuration_predictable_item_id
  end

  def self.down
    drop_table :predictions
  end
end
