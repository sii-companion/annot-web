class ChangeJobStdoutToLongtext < ActiveRecord::Migration[5.0]
  def change
    change_column :jobs, :stdout, :longtext
  end
end
