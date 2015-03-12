class AddGenomestatsLinks < ActiveRecord::Migration
  def change
    add_column :jobs, :genome_stat_id, :integer
    add_column :genome_stats, :job_id, :integer
  end
end
