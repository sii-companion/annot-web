require 'rack/utils'

def database_exists?
  ActiveRecord::Base.connection
rescue ActiveRecord::NoDatabaseError
  false
else
  true
end

desc 'Load all references from referencedirs in config/companion.yml, or specific sections with query args, e.g. load_references[Section1="/path/to/section1/"&Section2="/path/to/section2/"]'
task :load_references, [:args_expr] => :environment do |t, args|
    STDERR.puts "Checking for gt..."
    if not system("gt -version > /dev/null") then
      STDERR.puts "   Not found! Please install GenomeTools in your $PATH."
      exit 1
    end
    if not database_exists? then
      STDERR.puts "Creating db..."
      Rake::Task["db:create"].execute
      Rake::Task["db:migrate"].execute
      Rake::Task["db:seed"].execute
    end
    if args[:args_expr] then
      STDERR.puts "Using specific sections..."
      referencedirs = Rack::Utils.parse_nested_query(args[:args_expr])
    else
      referencedirs = CONFIG['referencedirs']
    end
    referencedirs.each do |section, refdir|
      STDERR.puts "Loading references for #{section}..."
      if Dir["#{refdir}/Ref*"].each do |groupdir|
        genes = []
        jsondata = File.open("#{groupdir}/references.json").read
        json = JSON.parse(jsondata)
        species = nil
        group = json["groups"].keys.first
        json["species"].keys.sort.each do |k|
          STDERR.puts " \u27A1 #{k}"
          r = Release.find_or_create_by(:species => k)
          newRelease = json["species"][k].try(:[], "metadata").try(:[], "Release")
          if not r[:number] or r[:number].to_i < newRelease.to_i then
          Kernel.system("#{CONFIG['rootdir']}/bin/genes_gff3_to_csv.lua #{groupdir}/#{k}/annotation.gff3 > 1")
          species = k
          File.open("1").read.each_line do |l|
            l.chomp!
            id, type, product, seqid, start, stop, strand = l.split("\t")
            g = Gene.find_or_initialize_by(:gene_id => id, :species => species, :job => nil)
            g.assign_attributes({:product => product, :loc_start => start, :loc_end => stop,
                      :strand => strand, :seqid => seqid, :gtype => type,
                      :genus => group, :section => section})
            if g[:loc_start] and g[:loc_end] and g[:seqid] and g[:species] and g[:gtype] then
              genes << g
            else
                STDERR.puts "   \u21AA Gene #{id} is missing vital part:"
              STDERR.puts g.inspect
            end
          end
          File.unlink("1")
            r[:number] = newRelease.to_i
            r.save!
          else
            STDERR.puts "   \u21AA Release number #{r[:number]} already present. Skipping."
          end
        end
        STDERR.puts "   Read #{genes.length} genes, importing."
        Gene.import genes, on_duplicate_key_update: :all
      end.empty?
        STDERR.puts "   Reference directories not found in #{refdir}."
      end
    end
    STDERR.puts "Done"
end