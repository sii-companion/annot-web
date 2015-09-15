class AddSectionToGene < ActiveRecord::Migration
  def change
    add_column :genes, :section, :string
  end
end
