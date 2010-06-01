class AllowUsersEmailNull < ActiveRecord::Migration
  def self.up
    change_column :users, :email, :string, :default => nil, :null => true
  end

  def self.down
    [:email].each do |field|
      User.all(:conditions => "#{field} is NULL").each { |user| user.update_attribute(field, "") if user.send(field).nil? }
      change_column :users, field, :string, :default => "", :null => false
    end
  end
end
