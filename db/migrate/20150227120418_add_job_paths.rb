class AddJobPaths < ActiveRecord::Migration
  def change
    add_column :jobs, :path, :string
  end
end
