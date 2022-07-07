class ChangeGeneProductToText < ActiveRecord::Migration[5.0]
  def change
    change_column :genes, :product, :text
  end
end
