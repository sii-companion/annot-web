module JobOutputs
  @@match_patterns = File.readlines("#{Rails.root.to_s}/config/match_patterns.txt", chomp: true)
  @@suffix_patterns = File.readlines("#{Rails.root.to_s}/config/transcript_patterns.txt", chomp: true)

  def match_gene_id(transcript_id)
    memb_id = nil
    @@match_patterns.each do |mtch|
      if transcript_id.match?(/#{mtch}/) then
        memb_id = transcript_id.match(/#{mtch}/)[1]
      end
    end
    if memb_id.nil? then
      memb_id = transcript_id.gsub(/#{@@suffix_patterns.join("|")}/,"")
    end
    memb_id
  end

  def import_clusters(job, ref)
    if File.exist?("#{job.job_directory}/orthomcl_out") then
      clusters = []
      File.open("#{job.job_directory}/orthomcl_out").each_line do |l|
        m = l.match(/^(OG[0-9]+):\s+(.+)/)
        next unless m
        c = Cluster.find_or_create_by(:cluster_id => m[1], :job => job)
        tr = m[2].scan(/[^|]+\|([^ )]+)/)
        tr.each do |memb|
          memb_id = self.match_gene_id(memb[0])
          g = Gene.where([
            "gene_id LIKE ? AND ((job_id = #{job[:id]} AND species = '#{job[:prefix]}')" \
            "OR (job_id IS NULL AND species = '#{ref[:abbr]}'))", "#{memb_id}%"
          ]).take
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
  end

  def gather_stats(job)
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
  end
end
