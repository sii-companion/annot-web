class ConvertReferenceIdToStr < ActiveRecord::Migration[5.0]
  def change
    change_column :jobs, :reference_id, :string
  end
end
