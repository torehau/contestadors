class CreateConfigurationIncludedSets < ActiveRecord::Migration
  def self.up
    create_table :configuration_included_sets do |t|
      t.integer :configuration_set_id
      t.integer :configuration_contest_id

      t.timestamps
    end
  end

  def self.down
    drop_table :configuration_included_sets
  end
end
