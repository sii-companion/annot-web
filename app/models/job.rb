class Job < ActiveRecord::Base
    belongs_to :user
    has_one :sequence_file
    has_one :transcript_file
    has_one :reference
    has_one :genome_stat
    has_many :circos_images
    has_many :result_files
    has_many :genes
    has_many :clusters
    has_one :tree

    def job_directory
      if not self[:job_id] then
        raise "no job ID yet"
      end
      Rails.root.join('public', 'jobs', self[:job_id])
    end

    def temp_directory
      if not self[:job_id] then
        raise "no job ID yet"
      end
      if not CONFIG['tmpdir'] then
        raise "CONFIG['tmpdir'] not set"
      end
      "#{CONFIG['tmpdir']}/#{self[:job_id]}"
    end

    def work_directory
      if not self[:job_id] then
        raise "no job ID yet"
      end
      if not CONFIG['workdir'] then
        raise "CONFIG['workdir'] not set"
      end
      "#{CONFIG['workdir']}/#{self[:job_id]}"
    end
end
