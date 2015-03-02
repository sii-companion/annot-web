class CreateUserFiles < ActiveRecord::Migration
  def change
    create_table :user_files do |t|
      t.string :path
      t.string :name
      t.integer :file_type_id
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
