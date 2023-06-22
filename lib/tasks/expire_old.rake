desc 'expire jobs older than 6 months'
task :expire_old => :environment do |t, args|
  oldjobs = Job.where("finished_at < :threshold", {:threshold => 6.months.ago})
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
    if File.exist?("#{job.work_directory}") then
      FileUtils.rm_rf("#{job.work_directory}")
    end
    job.destroy
    puts "Job #{job[:job_id]} '#{job[:name]}' was deleted."
  end
  puts "Deleting all genes created by jobs more than 6 months ago."
  run = "mysql -u#{ENV['COMPANION_DATABASE_USERNAME']} " + \
        "-p\"#{ENV['COMPANION_DATABASE_PASSWORD']}\" " + \
        "#{Rails.configuration.database_configuration[Rails.env]["database"]} " + \
        "-e \"delete from genes where created_at < DATE_SUB(NOW() , INTERVAL 6 MONTH) AND job_id IS NOT NULL\""
  Kernel.system(run)
  puts "Deleting all dragonfly files older than 6 months."
  Dir.glob("#{Dragonfly.app.datastore.root_path}/*/*/*/*").
    select{|f| File.mtime(f) < (Time.now - 6.months)}.
    each{|f| File.delete(f)}
end
