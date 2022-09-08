class AddGenusToGene < ActiveRecord::Migration[5.0]
  def change
    add_column :genes, :genus, :string
  end
end
