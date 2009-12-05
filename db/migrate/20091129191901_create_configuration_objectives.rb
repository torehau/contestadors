class CreateConfigurationObjectives < ActiveRecord::Migration
  def self.up
    create_table :configuration_objectives do |t|
      t.integer :configuration_category_id
      t.string :description
      t.string :predictable_field
      t.string :predictable_field_type
      t.integer :possible_points
      t.timestamps
    end
  end

  def self.down
    drop_table :configuration_objectives
  end
end
