module JobOutputs
  def import_clusters(job)
    if File.exist?("#{job.job_directory}/orthomcl_out") then
      clusters = []
      File.open("#{job.job_directory}/orthomcl_out").each_line do |l|
        m = l.match(/^(OG[0-9]+):\s+(.+)/)
        next unless m
        c = Cluster.find_or_create_by(:cluster_id => m[1], :job => job)
        tr = m[2].scan(/[^|]+\|([^ )]+)/)
        suffix_patterns = File.readlines("#{Rails.root.to_s}/config/transcript_suffix_patterns.txt", chomp: true)
        tr.each do |memb|
          memb_id = memb[0].gsub(/#{suffix_patterns.join("|")}/,"")
          g = Gene.where([
            "gene_id LIKE ? AND ((job_id = #{job[:id]} AND species = '#{job[:prefix]}')" \
            "OR (job_id IS NULL AND species = '#{r[:abbr]}'))", "#{memb_id}%"
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
end
