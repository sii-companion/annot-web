class ChangeIntegerLimitInGenomeStats < ActiveRecord::Migration[5.0]
  def change
    change_column :genome_stats, :overall_length, :integer, limit: 8    
  end
end
