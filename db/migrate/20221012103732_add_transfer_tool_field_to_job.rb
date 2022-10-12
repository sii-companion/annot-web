class AddTransferToolFieldToJob < ActiveRecord::Migration[5.0]
  def change
    add_column :jobs, :transfer_tool, :string
  end
end
