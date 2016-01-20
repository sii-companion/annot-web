class AddOrganismToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :organism, :string
  end
end
