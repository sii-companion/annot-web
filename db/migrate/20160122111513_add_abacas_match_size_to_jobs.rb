class AddAbacasMatchSizeToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :abacas_match_size, :integer
  end
end
