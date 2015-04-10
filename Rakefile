# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

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
    puts "loading references from #{CONFIG['referencedir']}..."
    jsondata = File.open("#{CONFIG['referencedir']}/references.json").read
    json = JSON.parse(jsondata)
    species = nil
    genes = []
    json["species"].keys.sort.each do |k|
      puts k
      Kernel.system("#{CONFIG['rootdir']}/bin/genes_gff3_to_csv.lua #{json["species"][k]['gff']} > 1")
      species = k
      File.open("1").read.each_line do |l|
        l.chomp!
        id, type, product, seqid, start, stop, strand = l.split("\t")
        g = Gene.new(:gene_id => id, :product => product, :loc_start => start,
                     :loc_end => stop, :strand => strand, :job => nil,
                     :seqid => seqid, :gtype => type, :species => species)
        if g[:loc_start] and g[:loc_end] and g[:seqid] and g[:species] and g[:gtype] then
          genes << g
        else
          puts "gene #{id} is missing vital part:"
          puts g.inspect
        end
      end
      File.unlink("1")
    end
    puts "read #{genes.length} genes, importing..."
    Gene.import(genes)
    puts "done"
end