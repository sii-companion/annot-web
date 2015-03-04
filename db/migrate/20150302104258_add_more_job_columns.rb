class AddMoreJobColumns < ActiveRecord::Migration
  def change
    add_column :jobs, :prefix, :string
    add_column :jobs, :ratt_transfer_type, :string
  end
end
