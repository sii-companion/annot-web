class Reference < ActiveFile::Base
  extend ActiveHash::Associations::ActiveRecordExtensions
  set_root_path CONFIG['referencedir']
  set_filename "references.json"

  class << self
    def extension
      ".json"
    end

    def load_file
      ref_key_map = {"pep" => :pepfile, "genome" => :ref_seq, "gaf" => :ref_gaf,
                     "chromosome_pattern" => :abacas_chr_pattern,
                     "chromosomes" => :ref_chr, "gff" => :ref_annot}
      jsondata = File.open("#{CONFIG['referencedir']}/references.json").read
      json = JSON.parse(jsondata)
      out = []
      i = 1
      json["species"].keys.sort.each do |k|
        v = json["species"][k]
        newhash = {:id => i, :abbr => k}
        v.each_pair do |k2,v2|
          if ref_key_map.has_key?(k2) then
            newhash[ref_key_map[k2]] = v2
          else
            newhash[k2] = v2
          end
        end
        if newhash.has_key?('augustus_model') then
          out << newhash
          i += 1
        end
      end
      out
    end
  end
end