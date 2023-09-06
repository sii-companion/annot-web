class AddApicoplastOverlapToJob < ActiveRecord::Migration[5.0]
  def change
    add_column :jobs, :apicoplast_overlap, :integer
  end
end
