class AddNoResumeToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :no_resume, :boolean
  end
end
