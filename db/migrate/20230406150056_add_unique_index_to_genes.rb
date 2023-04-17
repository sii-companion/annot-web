class AddUniqueIndexToGenes < ActiveRecord::Migration[5.0]
  def change
    add_index :genes, [:gene_id, :job_id, :species], unique: true
  end
end
