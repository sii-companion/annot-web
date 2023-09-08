class RenameOverlapColumn < ActiveRecord::Migration[5.0]
  def change
    rename_column :jobs, :apicoplast_overlap, :max_overlap
  end
end
