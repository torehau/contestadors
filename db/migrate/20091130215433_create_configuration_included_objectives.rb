class CreateConfigurationIncludedObjectives < ActiveRecord::Migration
  def self.up
    create_table :configuration_included_objectives do |t|
      t.integer :configuration_set_id
      t.integer :configuration_objective_id

      t.timestamps
    end
  end

  def self.down
    drop_table :configuration_included_objectives
  end
end
