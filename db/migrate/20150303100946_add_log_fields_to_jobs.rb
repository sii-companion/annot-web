class AddLogFieldsToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :stdout, :text
    add_column :jobs, :stderr, :text
  end
end
