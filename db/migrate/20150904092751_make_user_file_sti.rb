class MakeUserFileSti < ActiveRecord::Migration
  def change
    add_column :user_files, :type, :string
    remove_column :jobs, :user_file_id, :integer
    add_column :jobs, :sequence_file_id, :integer
    add_column :jobs, :transcript_file_id, :integer
  end
end
