require 'rack/utils'

def database_exists?
  ActiveRecord::Base.connection
rescue ActiveRecord::NoDatabaseError
  false
else
  true
end

task :load_references, [:args_expr] => :environment do |t, args|
    STDERR.puts "checking for gt..."
    if not system("gt -version > /dev/null") then
      STDERR.puts "not found! Please install GenomeTools in your $PATH."
      exit 1
    end
    if not database_exists? then
      STDERR.puts "creating db..."
      Rake::Task["db:create"].execute
      Rake::Task["db:migrate"].execute
      Rake::Task["db:seed"].execute
    end
    if args[:args_expr] then
      STDERR.puts "using specific sections"
      referencedirs = Rack::Utils.parse_nested_query(args[:args_expr])
    else
      referencedirs = CONFIG['referencedirs']
    end
    referencedirs.each do |section, refdir|
      STDERR.puts "loading references for #{section}..."
      Dir["#{refdir}/Ref*"].each do |groupdir|
        genes = []
        jsondata = File.open("#{groupdir}/references.json").read
        json = JSON.parse(jsondata)
        species = nil
        group = json["groups"].keys.first
        json["species"].keys.sort.each do |k|
          STDERR.puts k
          Kernel.system("#{CONFIG['rootdir']}/bin/genes_gff3_to_csv.lua #{groupdir}/#{k}/annotation.gff3 > 1")
          species = k
          File.open("1").read.each_line do |l|
            l.chomp!
            id, type, product, seqid, start, stop, strand = l.split("\t")
            g = Gene.find_or_create_by(:gene_id => id, :product => product, :loc_start => start,
                        :loc_end => stop, :strand => strand, :job => nil,
                        :seqid => seqid, :gtype => type, :species => species,
                        :section => section, :genus => group)
            if g[:loc_start] and g[:loc_end] and g[:seqid] and g[:species] and g[:gtype] then
              genes << g
            else
              STDERR.puts "gene #{id} is missing vital part:"
              STDERR.puts g.inspect
            end
          end
          File.unlink("1")
        end
        STDERR.puts "read #{genes.length} genes, importing..."
        Gene.import genes, on_duplicate_key_ignore: true
      end
    end
    STDERR.puts "done"
end