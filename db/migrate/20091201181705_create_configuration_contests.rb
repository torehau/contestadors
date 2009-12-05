class CreateConfigurationContests < ActiveRecord::Migration
  def self.up
    create_table :configuration_contests do |t|
      t.string :name
      t.datetime :available_from
      t.datetime :available_to
      t.datetime :participation_ends_at

      t.timestamps
    end
  end

  def self.down
    drop_table :configuration_contests
  end
end
