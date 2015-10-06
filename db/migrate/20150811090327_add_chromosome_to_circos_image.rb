class AddChromosomeToCircosImage < ActiveRecord::Migration
  def change
    add_column :circos_images, :chromosome, :string
  end
end
