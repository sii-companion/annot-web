class AddTreeId < ActiveRecord::Migration
  def change
    add_column :genes, :tree_id, :integer
  end
end
