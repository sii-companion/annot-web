class AddMd5ToResultFile < ActiveRecord::Migration
  def change
    add_column :result_files, :md5, :string
  end
end
