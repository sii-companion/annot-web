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

    # send job start notification email
    JobMailer.start_job_email(job.user, job).deliver_later

    begin
      # make result directory
      if not Dir.exist?(job.job_directory) then
        Dir.mkdir(job.job_directory)
      end

      # prepare starting Sidekiq job
      cf = JobsHelper::ConfigFactory.new
      uf = UserFile.find(job[:user_file_id])
      cf.use_target_seq(uf)
      r = Reference.find(job[:reference_id])
      cf.select_reference(r)
      cf.use_prefix(job[:prefix])
      cf.do_contiguation(job[:do_contiguate])
      cf.make_embl()
      cf.use_reference()
      cf.do_circos()
      cf.do_exonerate(job[:do_exonerate])
      job[:config_file] = cf.get_file(job).path
      job.save!

      # Nextflow run
      run = "#{CONFIG['nextflowpath']}/nextflow -c " + \
            "#{CONFIG['locationconfig']} -c " + \
            "#{job[:config_file]} run " + \
            "#{CONFIG['nextflowscript']} #{CONFIG['dockerconf']} " + \
            "#{'-resume' unless job[:no_resume]} " + \
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
      job.save!
      add_result_file(job, "pseudochr.fasta.gz")
      add_result_file(job, "pseudo.out.gff3")
      add_result_file(job, "pseudo.pseudochr.agp")
      add_result_file(job, "scafs.fasta.gz")
      add_result_file(job, "scaffold.out.gff3")
      add_result_file(job, "pseudo.scafs.agp")
      add_result_file(job, "out.gaf")
      add_result_file(job, "proteins.fasta")
      job.save!

      if (not status) or status.exitstatus != 0 then
        raise "run failed at nextflow stage"
      end

      # stats gathering
      if File.exist?("#{job.job_directory}/stats.txt") then
        gstat = GenomeStat.new
        File.open("#{job.job_directory}/stats.txt").read.each_line do |l|
          l.chomp!
          m = /^([^:]+):\s+(.+)$/.match(l)
          if m and gstat.has_attribute?(m[1].to_sym)
            gstat[m[1].to_sym] = m[2]
          end
        end
        gstat.save!
        job.genome_stat = gstat
        job.save!
      end

      # store circos images
      Dir.glob("#{job.job_directory}/chr*.png") do |f|
        img = CircosImage.new
        img.file = File.new(f)
        img.save!
        job.circos_images << img
        File.unlink(f)
      end

      # import genes
      if File.exist?("#{job.job_directory}/genelist.csv") then
        genes = []
        File.open("#{job.job_directory}/genelist.csv").read.each_line do |l|
          l.chomp!
          id, type, product, seqid, start, stop, strand = l.split("\t")
          g = Gene.new(:gene_id => id, :product => product, :loc_start => start,
                       :loc_end => stop, :strand => strand, :job => job,
                       :seqid => seqid, :gtype => type, :species => job[:prefix])
          genes << g
        end
        Gene.import(genes)
      end

      # import clusters
      if File.exist?("#{job.job_directory}/orthomcl_out") then
        clusters = []
        File.open("#{job.job_directory}/orthomcl_out").each_line do |l|
          m = l.match(/^(ORTHOMCL[0-9]+)[^:]+:\s+(.+)/)
          next unless m
          c = Cluster.new(:cluster_id => m[1], :job => job)
          r = m[2].scan(/([^ ()]+)\([^)]+\)/)
          r.each do |memb|
            # HACK! needs to be done correctly for all possible transcript namings!
            memb_id = memb[0].gsub(/(:.+$|\.\d+$)/,"")
            g = Gene.where(["gene_id LIKE ? AND (job_id = #{job[:id]} OR job_id IS NULL)", "#{memb_id}%"]).take
            raise "#{memb[0]}: #{memb_id} (with job ID #{job[:id]}) not found!" unless g
            c.genes << g
          end
          c.save!
        end
      end

      # store tree files
      if File.exist?("#{job.job_directory}/tree_selection.genes") and
        File.exist?("#{job.job_directory}/tree.aln") then
        genes = []
        t = Tree.new(job: job)
        t.seq = File.new("#{job.job_directory}/tree.aln")
        t.save!
        File.open("#{job.job_directory}/tree_selection.genes").each_line do |l|
          l.chomp!
          l.split(/\s+/).each do |memb|
            # HACK! needs to be done correctly for all possible transcript namings!
            memb_id = memb.gsub(/(:[^:]+$|\.\d+$)/,"")
            g = Gene.where(["gene_id LIKE ? AND (job_id = #{job[:id]} OR job_id IS NULL)", "#{memb_id}%"]).take
            raise "#{memb}: #{memb_id} (with job ID #{job[:id]}) not found!" unless g
            t.genes << g
          end
          t.save!
        end
      end

      job[:finished_at] = DateTime.now
      job.save!

      # send finish notification email
      JobMailer.finish_success_job_email(job.user, job).deliver_later
    rescue => e
      # send error notification email
      JobMailer.finish_failure_job_email(job.user, job).deliver_later
      raise e
    end

  end
end