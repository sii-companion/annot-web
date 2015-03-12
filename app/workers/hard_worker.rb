class HardWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false, :dead => false
  include Sidekiq::Status::Worker

  def expiration
    @expiration ||= 60*60*24*30*12*15 # keep jobs around for a long time
  end

  def with_environment(variables={})
    if block_given?
      old_values = variables.map{ |k,v| [k,ENV[k]] }
      begin
         variables.each{ |k,v| ENV[k] = v }
         result = yield
      ensure
        old_values.each{ |k,v| ENV[k] = v }
      end
      result
    else
      variables.each{ |k,v| ENV[k] = v }
    end
  end

  def add_result_file(job, file)
    if File.exist?("#{job.job_directory}/#{file}") then
      rf = ResultFile.new
      rf.file = File.new("#{job.job_directory}/#{file}")
      rf.save!
      job.result_files << rf
    else
      raise "required file not present: #{job.job_directory}/#{file}"
    end
  end

  # TODO: modularize this
  def perform(id)
    job = Job.find(id)
    store name: job[:name]
    store job_id: @jid
    my_stdout = nil
    my_stderr = nil
    status = nil

    # start job
    job[:started_at] = DateTime.now
    job[:job_id] = @jid
    job.save!

    if not Dir.exist?(job.job_directory) then
      Dir.mkdir(job.job_directory)
    end

    # prepare starting Sidekiq job
    cf = JobsHelper::ConfigFactory.new
    uf = UserFile.find(job[:user_file_id])
    cf.use_target_seq(uf)
    cf.use_reference(Reference.find(job[:reference_id]))
    cf.use_prefix(job[:prefix])
    cf.do_contiguation(job[:do_contiguate])
    cf.do_exonerate(job[:do_exonerate])
    job[:config_file] = cf.get_file(job).path
    job.save!

    # Nextflow run
    run = "#{CONFIG['nextflowpath']}/nextflow -c " + \
          "#{CONFIG['locationconfig']} -c " + \
          "#{job[:config_file]} run " + \
          "#{CONFIG['nextflowscript']} #{CONFIG['dockerconf']} -resume " + \
          "--dist_dir #{job.job_directory}"
    puts run
    with_environment("ROOTDIR" => "#{CONFIG['rootdir']}",
                     "NXF_WORK" => "#{CONFIG['workdir']}",
                     "NXF_TEMP" => "#{CONFIG['tmpdir']}") do
      status = Open4::popen4(run) do |pid, stdin, stdout, stderr|
        my_stdout = stdout.readlines.join
        my_stderr = stderr.readlines.join
      end
    end
    puts "STDOUT:"
    puts my_stdout
    puts "STDERR:"
    puts my_stderr

    job[:finished_at] = DateTime.now
    job[:stderr] = my_stderr
    job[:stdout] = my_stdout
    add_result_file(job, "pseudochr.fasta.gz")
    add_result_file(job, "pseudo.out.gff3")
    add_result_file(job, "pseudo.pseudochr.agp")
    add_result_file(job, "scafs.fasta.gz")
    add_result_file(job, "scaffold.out.gff3")
    add_result_file(job, "pseudo.scafs.agp")
    add_result_file(job, "out.gaf")
    job.save!

    if (not status) or status.exitstatus != 0 then
      raise "run failed at nextflow stage"
    end

    # Stats gathering
    if File.exist?("#{job.job_directory}/stats.txt") then
      gstat = GenomeStat.new
      File.open("#{job.job_directory}/stats.txt").read.each_line do |l|
        l.chomp!
        puts l
        m = /^([^:]+):\s+(.+)$/.match(l)
        if m and gstat.has_attribute?(m[1].to_sym)
          gstat[m[1].to_sym] = m[2]
        end
      end
      gstat.save!
      job.genome_stat = gstat
      job.save!
    end

    # Store circos images
    Dir.glob("#{job.job_directory}/chr*.png") do |f|
      img = CircosImage.new
      img.file = File.new(f)
      img.save!
      job.circos_images << img
      File.unlink(f)
    end

    # create tree
    job[:finished_at] = DateTime.now
    job.save!
  end
end