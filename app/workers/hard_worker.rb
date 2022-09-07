class HardWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 0
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
    file_path = "#{job.job_directory}/#{file}"
    if File.exist?(file_path) then
      # prevent duplication for job restarts
      rf = job.result_files.where(:file_name => file).take
      if not rf then
        rf = ResultFile.new
        job.result_files << rf
      end
      rf.file = File.new(file_path)
      rf.md5 = Digest::MD5.file(file_path).hexdigest
      rf.save!
    else
      raise "required file not present: #{job.job_directory}/#{file}"
    end
  end

  def make_directories(job)
    # make result directory
    if not Dir.exist?(job.job_directory) then
      FileUtils.mkdir_p(job.job_directory)
    end

    # make temp directory
    if not Dir.exist?(job.temp_directory) then
      FileUtils.mkdir_p(job.temp_directory)
    end

    # make work directory
    if not Dir.exist?(job.work_directory) then
      FileUtils.mkdir_p(job.work_directory)
    end
  end

  def perform(id)
    # wait a bit to minimize timing issues
    Kernel.sleep(5)

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
    if job[:email] and job[:email].length > 0 then
      JobMailer.start_job_email(job).deliver_later
    end

    begin
      # make necessary run directories
      make_directories(job)

      # prepare starting Sidekiq job
      cf = JobsHelper::ConfigFactory.new
      uf = job.sequence_file
      cf.use_target_seq(uf)
      r = Reference.find(job[:reference_id])
      cf.select_reference(r)
      cf.use_prefix(job[:prefix])
      cf.do_contiguation(job[:do_contiguate] && r.has_chromosomes?)
      if job[:use_transcriptome_data] then
        tf = job.transcript_file
        if tf then
          cf.use_transcript_file(tf)
        end
      end
      cf.make_embl()
      cf.use_reference()
      cf.do_exonerate(job[:do_exonerate])
      cf.run_ratt(job[:do_ratt])
      cf.run_liftoff(job[:do_liftoff])
      cf.do_pseudo(job[:do_pseudo])
      job[:config_file] = cf.get_file(job).path
      job.save!

      # Nextflow run
      run = "#{CONFIG['nextflowpath']}/nextflow -c " + \
            "#{CONFIG['locationconfig']} -c " + \
            "#{job[:config_file]} run " + \
            "#{CONFIG['nextflowscript']} #{CONFIG['dockerconf']} " + \
            "#{'-resume' unless job[:no_resume]} " + \
            "--dist_dir #{job.job_directory} " + \
            "-with-trace -with-timeline " + \
            "-ansi-log false"  # Warning: Only compatable with nextflow versions >= 19.04.0
      Rails.logger.info run
      Dir.chdir(job.job_directory) do
        with_environment("ROOTDIR" => "#{CONFIG['rootdir']}",
                        "NXF_WORK" => job.work_directory,
                        "NXF_TEMP" => job.temp_directory) do
          status = Open4::popen4(run) do |pid, stdin, stdout, stderr|
            my_stdout = stdout.readlines.join
            my_stderr = stderr.readlines.join
          end
        end
      end
      Rails.logger.info "STDOUT:"
      Rails.logger.info my_stdout
      Rails.logger.info "STDERR:"
      Rails.logger.info my_stderr

      job[:stderr] = my_stderr
      job[:stdout] = my_stdout
      job.save!

      # job finished successfully but no annotations were created
      if status == 0 and !File.exist?("#{job.job_directory}/pseudo.out.gff3") then
        gstat = GenomeStat.new
        gstat[:nof_genes] = 0
        gstat.save!
        job.genome_stat = gstat
        job.save!
      else
        # zip up EMBL files
        Kernel.system("cd #{job.job_directory}; tar -czf #{job.job_directory}/embl.tar.gz *.embl")
        if File.exist?("#{job.job_directory}/embl.tar.gz") then
          Kernel.system("rm -f #{job.job_directory}/*.embl")
        end

        add_result_file(job, "pseudochr.fasta.gz")
        add_result_file(job, "pseudo.out.gff3")
        add_result_file(job, "pseudo.pseudochr.agp")
        add_result_file(job, "scafs.fasta.gz")
        add_result_file(job, "scaffold.out.gff3")
        add_result_file(job, "pseudo.scafs.agp")
        add_result_file(job, "embl.tar.gz") if File.exist?("#{job.job_directory}/embl.tar.gz")
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
          m = f.match(/chr(.+)\.png$/)
          if not m.nil? then
            chrname = m[1]
          else
            chrname = "unnamed chromosome"
          end
          file = File.new(f)
          # prevent duplication for job restarts
          img = job.circos_images.where(:chromosome => chrname).take
          if not img then
            img = CircosImage.new(chromosome: chrname)
            job.circos_images << img
          end 
          img.file = file
          img.save!          
          File.unlink(f)
        end

        # import genes
        if File.exist?("#{job.job_directory}/genelist.csv") then
          genes = []
          File.open("#{job.job_directory}/genelist.csv").read.each_line do |l|
            l.chomp!
            id, type, product, seqid, start, stop, strand = l.split("\t")
            g = Gene.find_or_create_by(:gene_id => id, :product => product, :loc_start => start,
                         :loc_end => stop, :strand => strand, :job => job,
                         :seqid => seqid, :gtype => type, :species => job[:prefix],
                         :section => r[:section])
            genes << g
          end
          Gene.import genes, on_duplicate_key_ignore: true
        end

        # import clusters
        if File.exist?("#{job.job_directory}/orthomcl_out") then
          clusters = []
          File.open("#{job.job_directory}/orthomcl_out").each_line do |l|
            m = l.match(/^(ORTHOMCL[0-9]+):\s+(.+)/)
            next unless m
            c = Cluster.find_or_create_by(:cluster_id => m[1], :job => job)
            r = m[2].scan(/[^|]+\|([^ )]+)/)
            r.each do |memb|
              # HACK! needs to be done correctly for all possible transcript namings!
              memb_id = memb[0].gsub(/(:.+$|\.\d+$|\.mRNA$|\_R[A-Z]$)/,"")
              g = Gene.where(["gene_id LIKE ? AND (job_id = #{job[:id]} OR job_id IS NULL)", "#{memb_id}%"]).take
              if g then
                unless g.in?(c.genes)
                  c.genes << g
                end
              else
                Rails.logger.info("#{memb[0]}: #{memb_id} (with job ID #{job[:id]}) not found!")
              end
            end
            c.save!
          end
        end

        # store tree files
        if File.exist?("#{job.job_directory}/tree_selection.genes") and
          File.exist?("#{job.job_directory}/tree.aln") then
          genes = []
          t = Tree.find_or_create_by(job: job)
          t.seq = File.new("#{job.job_directory}/tree.aln")
          t.save!
          File.open("#{job.job_directory}/tree_selection.genes").each_line do |l|
            l.chomp!
            l.split(/\s+/).each do |memb|
              # HACK! needs to be done correctly for all possible transcript namings!
              memb_id = memb.gsub(/(:[^:]+$|\.\d+$)/,"")
              g = Gene.where(["gene_id LIKE ? AND (job_id = #{job[:id]} OR job_id IS NULL)", "#{memb_id}%"]).take
              if g then
                unless g.in?(t.genes)
                  t.genes << g
                end
              else
                Rails.logger.info("#{memb}: #{memb_id} (with job ID #{job[:id]}) not found!")
              end
            end
            t.save!
          end
        end
      end

      job[:finished_at] = DateTime.now
      job.save!

      # clean up directories
      if not CONFIG['keep_work_directories'] then
        FileUtils.rm_rf(job.temp_directory)
        FileUtils.rm_rf(job.work_directory)
      end

      # send finish notification email
      if job[:email] and job[:email].length > 0 then
        JobMailer.finish_success_job_email(job).deliver_later
      end
    rescue => e
      job[:finished_at] = DateTime.now
      errstr = "#{e.backtrace.first}: #{e.message} (#{e.class})\n"
      errstr += e.backtrace.drop(1).map{|s| "\t#{s}"}.join("\n")
      if job[:stderr] then
        job[:stderr] = job[:stderr] + "\n" + errstr
      else
        job[:stderr] = errstr
      end

      job.save!
      # send error notification email
      if job[:email] and job[:email].length > 0 then
        JobMailer.finish_failure_job_email(job).deliver_later
      end
      JobMailer.finish_failure_job_email_notify_dev(job).deliver_later
      raise e
    end
  end
end
