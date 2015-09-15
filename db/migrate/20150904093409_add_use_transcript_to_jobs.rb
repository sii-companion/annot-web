class AddUseTranscriptToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :use_transcriptome_data, :boolean
  end
end
