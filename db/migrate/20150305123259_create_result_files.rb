class CreateResultFiles < ActiveRecord::Migration
  def change
    create_table :result_files do |t|
      t.string :file_uid
      t.string :file_name
      t.integer :job_id

      t.timestamps null: false
    end
  end
end
