class AddContestInstancesAllowJoinByUrl < ActiveRecord::Migration
  def self.up
    add_column :contest_instances, :allow_join_by_url, :boolean
  end

  def self.down
    remove_column :contest_instances, :allow_join_by_url
  end
end
