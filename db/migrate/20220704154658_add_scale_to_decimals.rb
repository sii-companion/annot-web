class AddScaleToDecimals < ActiveRecord::Migration[5.0]
  def change
    change_column(:jobs, :augustus_score_threshold, :decimal, {precision: 10, scale: 2})
  end
end
