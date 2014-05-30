class CreateOperationSettings < ActiveRecord::Migration
  def self.up
    create_table :operation_settings do |t|
      t.boolean :is_under_maintenance
      t.string :admin_user

      t.timestamps
    end
  end

  def self.down
    drop_table :operation_settings
  end
end
