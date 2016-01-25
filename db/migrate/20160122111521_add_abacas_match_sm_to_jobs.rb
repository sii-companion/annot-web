class AddAbacasMatchSmToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :abacas_match_sim, :integer
  end
end
