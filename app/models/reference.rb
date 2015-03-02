class Reference < ActiveHash::Base
  self.data = [
    {:id => 1,
     :name => "Leishmania major Friedlin",
     :abbr => "LmjF",
     :ref_seq => "#{CONFIG['rootdir']}/example-data/L_major.fasta.1",  ## FIXME
     :ref_gaf => "#{CONFIG['rootdir']}/example-data/Lmajor.gff3.1",
     :augustus_species => "leishmania_major_sampled"},
    {:id => 2,
     :name => "Trypanosoma brucei TREU927",
     :abbr => "Tb927",
     :ref_seq => "#{CONFIG['rootdir']}/example-data/L_major.fasta.1",  ## FIXME
     :ref_gaf => "#{CONFIG['rootdir']}/example-data/Lmajor.gff3.1",
     :augustus_species => "leishmania_major_sampled"},
     {:id => 3,
     :name => "Leishmania braziliensis MHOM/BR/75/M2904",
     :abbr => "LbrM",
     :ref_seq => "#{CONFIG['rootdir']}/example-data/L_major.fasta.1",  ## FIXME
     :ref_gaf => "#{CONFIG['rootdir']}/example-data/Lmajor.gff3.1",
     :augustus_species => "leishmania_major_sampled"}
  ]
end


