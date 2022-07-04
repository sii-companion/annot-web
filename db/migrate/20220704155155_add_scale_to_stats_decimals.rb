class AddScaleToStatsDecimals < ActiveRecord::Migration[5.0]
  def change
    change_table :genome_stats do |t|
      t.change :gc_overall, :decimal,  {precision: 10, scale: 2}
      t.change :gc_coding, :decimal,  {precision: 10, scale: 2}
      t.change :gene_density, :decimal,  {precision: 10, scale: 2}
      t.change :avg_coding_length, :decimal,  {precision: 10, scale: 2}
    end
  end
end
