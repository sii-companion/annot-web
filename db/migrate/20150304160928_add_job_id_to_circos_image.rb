class AddJobIdToCircosImage < ActiveRecord::Migration
  def change
    add_column :circos_images, :job_id, :integer
  end
end
