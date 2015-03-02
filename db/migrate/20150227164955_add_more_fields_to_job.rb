class AddMoreFieldsToJob < ActiveRecord::Migration
  def change
    add_column :jobs, :do_contiguate, :boolean
    add_column :jobs, :do_exonerate, :boolean
    add_column :jobs, :do_ratt, :boolean
    add_column :jobs, :max_gene_length, :integer
    add_column :jobs, :augustus_score_threshold, :decimal
    add_column :jobs, :taxon_id, :integer
    add_column :jobs, :db_id, :string
    add_column :jobs, :reference_id, :integer
  end
end
