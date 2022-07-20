class AddDoLiftoffFieldToJob < ActiveRecord::Migration[5.0]
  def change
    add_column :jobs, :do_liftoff, :boolean
  end
end
