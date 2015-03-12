class Job < ActiveRecord::Base
    belongs_to :user
    has_one :user_file
    has_one :reference
    has_one :genome_stat
    has_many :circos_images
    has_many :result_files

    def job_directory
      if not self[:job_id] then
        raise "no job ID yet"
      end
      Rails.root.join('public', 'jobs', self[:job_id])
    end
end
