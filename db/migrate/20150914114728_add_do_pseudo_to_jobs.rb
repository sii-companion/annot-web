class AddDoPseudoToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :do_pseudo, :boolean
  end
end
