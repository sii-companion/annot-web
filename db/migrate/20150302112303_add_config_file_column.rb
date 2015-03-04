class AddConfigFileColumn < ActiveRecord::Migration
  def change
    add_column :jobs, :config_file, :string
  end
end
