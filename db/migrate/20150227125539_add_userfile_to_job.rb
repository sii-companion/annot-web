class AddUserfileToJob < ActiveRecord::Migration
  def change
    add_column :jobs, :user_file_id, :integer
  end
end
