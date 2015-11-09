class AddJobToUserFile < ActiveRecord::Migration
  def change
    add_column :user_files, :job_id, :integer
  end
end
