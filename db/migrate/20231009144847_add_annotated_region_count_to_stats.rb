class AddAnnotatedRegionCountToStats < ActiveRecord::Migration[5.0]
  def change
    add_column :genome_stats, :nof_annotated_regions, :integer
  end
end
