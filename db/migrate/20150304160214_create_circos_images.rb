class CreateCircosImages < ActiveRecord::Migration
  def change
    create_table :circos_images do |t|
      t.string :file_uid
      t.string :file_name
      t.timestamps null: false
    end
  end
end
