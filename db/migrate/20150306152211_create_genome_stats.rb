class CreateGenomeStats < ActiveRecord::Migration
  def change
    create_table :genome_stats do |t|
      t.integer :nof_regions
      t.integer :overall_length
      t.decimal :gc_overall
      t.decimal :gc_coding
      t.integer :nof_genes
      t.decimal :gene_density
      t.decimal :avg_coding_length
      t.integer :nof_coding_genes
      t.integer :nof_genes_with_mult_cds
      t.integer :nof_genes_with_function

      t.timestamps null: false
    end
  end
end
