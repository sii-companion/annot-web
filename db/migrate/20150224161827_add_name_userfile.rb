class AddNameUserfile < ActiveRecord::Migration
  def change
     add_column :user_files, :path_name, :string
  end
end
