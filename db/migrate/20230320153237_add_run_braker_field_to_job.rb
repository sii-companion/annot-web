class AddRunBrakerFieldToJob < ActiveRecord::Migration[5.0]
  def change
    add_column :jobs, :run_braker, :boolean
  end
end
