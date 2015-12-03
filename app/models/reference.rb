class Reference < ActiveFile::Base
  extend ActiveHash::Associations::ActiveRecordExtensions

  class << self
    def extension
      ".json"
    end

    def load_file
      ref_key_map = {}
      out = []
      i = 1
      CONFIG['referencedirs'].each do |section,referencedir|
        jsondata = File.open("#{referencedir}/references.json").read
        json = JSON.parse(jsondata)
        json["species"].keys.sort.each do |k|
          v = json["species"][k]
          newhash = {:id => i, :abbr => k, :section => section,
                     :referencedir => referencedir}
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
            i += 1
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
    out = "#{self[:name]} (#{self[:nof_genes]} genes"
    if self.has_chromosomes? then
      out = out + ", #{self[:nof_chromosomes]} chromosomes"
    end
    out = out + ")"
  end
end