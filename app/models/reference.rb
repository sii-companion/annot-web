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
          if newhash.has_key?('augustus_model') then
            out << newhash
            i += 1
          end
        end
      end
      out
    end
  end
end