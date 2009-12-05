class CreateConfigurationSets < ActiveRecord::Migration
  def self.up
    create_table :configuration_sets do |t|
      t.string :description
      t.boolean :mutex_objectives

      t.timestamps
    end
  end

  def self.down
    drop_table :configuration_sets
  end
end
