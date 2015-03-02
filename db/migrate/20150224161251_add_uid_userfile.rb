class AddUidUserfile < ActiveRecord::Migration
  def change
     add_column :user_files, :path_uid, :string
     remove_column :user_files, :path
  end
end
