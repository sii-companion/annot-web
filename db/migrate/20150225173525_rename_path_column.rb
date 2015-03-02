class RenamePathColumn < ActiveRecord::Migration
  def change
    rename_column :user_files, :path_uid, :file_uid
    rename_column :user_files, :path_name, :file_name
  end
end
