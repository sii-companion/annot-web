class AddPseudogenesToGenomeStats < ActiveRecord::Migration
  def change
    add_column :genome_stats, :nof_pseudogenes, :integer
    add_column :genome_stats, :nof_pseudogenes_with_function, :integer
  end
end
