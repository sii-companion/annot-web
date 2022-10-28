class AddGeneTimestamps < ActiveRecord::Migration[5.0]  
  def change
    add_timestamps :genes, null: false, default: -> { 'NOW()' }    
  end
end
