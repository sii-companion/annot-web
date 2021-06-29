desc 'expire jobs older than 4 months'
task :expire_old => :environment do |t, args|
  oldjobs = Job.where("finished_at < :threshold", {:threshold => 4.months.ago})
  oldjobs.each do |job|
    if CONFIG['example_job_id'] == job['job_id'] then
      puts "Job #{job[:job_id]} '#{job[:name]}' is marked as the example, skipping it"
      next
    end
    if job.sequence_file then
      job.sequence_file.destroy
    end
    if job.transcript_file then
      job.transcript_file.destroy
    end
    if File.exist?("#{job.job_directory}") then
      FileUtils.rm_rf("#{job.job_directory}")
    end
    job.destroy
    puts "Job #{job[:job_id]} '#{job[:name]}' was deleted."
  end
end
