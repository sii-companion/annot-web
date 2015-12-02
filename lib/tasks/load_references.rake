task :load_references => :environment do |t, args|
    puts "checking for gt..."
    if not system("gt -version > /dev/null") then
      puts "not found! Please install GenomeTools in your $PATH."
      exit 1
    end
    puts "clearing references..."
    Rake::Task["db:drop"].execute
    Rake::Task["db:create"].execute
    Rake::Task["db:migrate"].execute
    Rake::Task["db:seed"].execute
    CONFIG['referencedirs'].each do |section, refdir|
      genes = []
      puts "loading references for #{section}..."
      jsondata = File.open("#{refdir}/references.json").read
      json = JSON.parse(jsondata)
      species = nil
      group = {}
      json["species"].keys.sort.each do |k|
        STDERR.puts k
        Kernel.system("#{CONFIG['rootdir']}/bin/genes_gff3_to_csv.lua #{refdir}/#{k}/annotation.gff3 > 1")
        species = k
        File.open("1").read.each_line do |l|
          l.chomp!
          id, type, product, seqid, start, stop, strand = l.split("\t")
          g = Gene.new(:gene_id => id, :product => product, :loc_start => start,
                       :loc_end => stop, :strand => strand, :job => nil,
                       :seqid => seqid, :gtype => type, :species => species,
                       :section => section)
          if g[:loc_start] and g[:loc_end] and g[:seqid] and g[:species] and g[:gtype] then
            genes << g
          else
            STDERR.puts "gene #{id} is missing vital part:"
            STDERR.puts g.inspect
          end
        end
        File.unlink("1")
      end
      STDERR.print "read #{genes.length} genes, importing..."
      Gene.import(genes)
    end
    STDERR.puts "done"
end