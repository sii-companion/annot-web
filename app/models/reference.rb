class Reference < ActiveFile::Base
  extend ActiveHash::Associations::ActiveRecordExtensions

  class << self
    def extension
      ".json"
    end

    def load_file
      ref_key_map = {}
      out = []
      CONFIG['referencedirs'].each do |section,referencedir|
        Dir["#{referencedir}/Ref*"].each do |groupdir|
          jsondata = File.open("#{groupdir}/references.json").read
          json = JSON.parse(jsondata)
          group = json["groups"].keys.first
          json["species"].keys.sort.each do |k|
            v = json["species"][k]
            newhash = {:id => k, :abbr => k, :section => section, :genus => group,
                      :referencedir => groupdir}
            # assign weightfile for this section, if configured
            if CONFIG['weightfiles'] and CONFIG['weightfiles'][section] then
              newhash[:weightfile] = CONFIG['weightfiles'][section]
            end
            # assign maxintronlen for this section, if configured
            if CONFIG['maxintronlengths'] and CONFIG['maxintronlengths'][section] then
              newhash[:maxintronlen] = CONFIG['maxintronlengths'][section]
            end
            # assign fix_polycistrons for this section, if configured
            if CONFIG['fix_polycistrons'] and CONFIG['fix_polycistrons'][section] then
              newhash[:fix_polycistrons] = CONFIG['fix_polycistrons'][section]
            end
            # assign do_circos for this section, if configured
            if CONFIG['do_circos'] and CONFIG['do_circos'][section] then
              newhash[:do_circos] = CONFIG['do_circos'][section]
            end
            # assign run_braker for this section, if configured
            if CONFIG['run_braker'] and CONFIG['run_braker'][section] then
              newhash[:run_braker] = CONFIG['run_braker'][section]
            end
            # assign is_fungi for this section, if configured
            if CONFIG['is_fungi'] and CONFIG['is_fungi'][section] then
              newhash[:is_fungi] = CONFIG['is_fungi'][section]
            end
            # lift over properties from JSON
            v.each_pair do |k2,v2|
              if ref_key_map.has_key?(k2) then
                newhash[ref_key_map[k2]] = v2
              else
                newhash[k2] = v2
              end
            end
            # we need at least an AUGUSTUS model to use this species as a
            # direct reference
            if newhash.has_key?('augustus_model') and newhash.has_key?('is_reference_strain') then
              out << newhash
            end
          end
        end
      end
      out
    end
  end

  def has_chromosomes?
    return (self[:nof_chromosomes] and self[:nof_chromosomes] > 0 \
      and File.exist?(File.join(self[:referencedir], self[:abbr], 'chromosomes.fasta')))
  end

  def name_with_genes
    out = "#{self[:name]} (#{self[:nof_genes]} #{"gene".pluralize(self[:nof_genes].to_i)}"
    if self.has_chromosomes? then
      out = out + ", #{self[:nof_chromosomes]} #{"chromosome".pluralize(self[:nof_chromosomes].to_i)}"
    end
    out = out + ")"
  end
end