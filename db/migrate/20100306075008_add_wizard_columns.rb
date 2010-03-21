class AddWizardColumns < ActiveRecord::Migration
  def self.up
    add_column :configuration_contests, :predictable_module, :string
    add_column :configuration_contests, :permalink, :string
    add_column :prediction_summaries, :configuration_contest_id, :integer
  end

  def self.down
    remove_column :configuration_contests, :predictable_module
    remove_column :configuration_contests, :permalink
    remove_column :prediction_summaries, :configuration_contest_id
  end
end
