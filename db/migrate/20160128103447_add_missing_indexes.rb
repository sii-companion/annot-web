class AddMissingIndexes < ActiveRecord::Migration
  def change
    add_index :circos_images, :job_id
    add_index :trees, :job_id
    add_index :user_files, [:id, :type]
    add_index :user_files, :job_id
    add_index :result_files, :job_id
    add_index :jobs, :user_id
    add_index :genome_stats, :job_id
  end
end