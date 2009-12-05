class CreateConfigurationCategories < ActiveRecord::Migration
  def self.up
    create_table :configuration_categories do |t|
      t.string :description
      t.string :predictable_type
      t.timestamps
    end
  end

  def self.down
    drop_table :configuration_categories
  end
end
