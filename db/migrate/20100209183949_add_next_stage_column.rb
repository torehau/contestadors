class AddNextStageColumn < ActiveRecord::Migration
  def self.up
    add_column :predictable_championship_stages, :next_stage_id, :integer
  end

  def self.down
    remove_column :predictable_championship_stages, :next_stage_id
  end
end
