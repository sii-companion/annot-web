class AddSpecies < ActiveRecord::Migration
  def change
    add_column :genes, :species, :string
  end
end
