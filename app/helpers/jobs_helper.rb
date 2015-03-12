require 'tempfile'

module JobsHelper
    @fnmaps = {"pseudochr.fasta.gz" => "Pseudochromosome level genomic sequence (FASTA)",
              "scafs.fasta.gz" => "Scaffold level genomic sequence (FASTA)",
              "pseudo.out.gff3" => "Pseudochromosome level genes (GFF3)",
              "scaffold.out.gff3" => "Scaffold level genes (GFF3)",
              "pseudo.pseudochr.agp" => "Pseudochromosome layout (AGP)",
              "pseudo.scafs.agp" => "Scaffold layout (AGP)",
              "out.gaf" => "Functional GO annotation (GAF1)"}

    def file_description(fn)
      if @fnmaps[fn] then
        @fnmaps[fn]
      else
        fn
      end
    end
    module_function :file_description

    class ConfigFactory
      def initialize
        @items = {}
        @omcl_pepfiles = []
      end

      def add_item(key, val)
        @items[key] = val
      end

      def use_prefix(prefix)
        @items["GENOME_PREFIX"] = prefix
        @items["CHR_PATTERN"] = "#{prefix}_(%d+)"
        @items["ABACAS_CHR_PREFIX"] = prefix
        @items["ABACAS_SEQ_PREFIX"] = prefix
        @items["ABACAS_BIN_CHR"] = "#{prefix}_0"
      end

      def do_exonerate(val = true)
        @items["run_exonerate"] = val
      end

      def do_contiguation(val = true)
        @items["do_contiguation"] = val
      end

      def use_reference(ref)
        @items["ref_seq"] = ref[:ref_seq]
        @items["ref_chr"] = ref[:ref_chr]
        @items["ref_annot"] = ref[:ref_annot]
        @items["AUGUSTUS_SPECIES"] = ref[:augustus_species]
        @items["ABACAS_CHR_PATTERN"] = ref[:abacas_chr_pattern]
        @items["OMCL_GFFFILE"] = ref[:ref_annot]
        @items["OMCL_GAFFILE"] = ref[:ref_gaf]
        add_omcl_pepfile(ref[:abbr], ref[:pepfile])
      end

      def get_target_seq(val)
        target_path = Rails.root.join('public', 'system', 'dragonfly', Rails.env)
        target_path = target_path.join(val[:file_uid])
      end

      def use_target_seq(val)
        target_path = get_target_seq(val)
        raise unless File.exist?(target_path)
        @items["inseq"] = target_path
      end

      def add_omcl_pepfile(prefix, file)
        @omcl_pepfiles.push([prefix, file])
        @omcl_pepfiles.uniq!
      end

      def get_file(job)
        add_item("RATT_TRANSFER_TYPE", job[:ratt_transfer_type])
        add_item("MAX_GENE_LENGTH", job[:max_gene_length])
        add_item("AUGUSTUS_GENEMODEL", 'intronless')
        add_item("AUGUSTUS_EXTRINSIC_CFG", CONFIG['extrinsicconfig'])
        add_item("AUGUSTUS_HINTS_MAXINTRONLEN", '1')
        add_item("AUGUSTUS_SCORE_THRESHOLD", job[:augustus_score_threshold].round(2))
        add_item("TAXON_ID", job[:taxon_id])
        add_item("DB_ID", job[:db_id])
        # TODO: add checks for validity
        out  = "params {\n"
        @items.each do |k,v|
          if v.to_s.match(/^[0-9.]+$/) or v.to_s.match(/^(true|false)$/) then
            out += "    #{k}  =  #{v}\n"
          else
            out += "    #{k}  =  '#{v}'\n"
          end
        end
        if @omcl_pepfiles.size > 0 then
          out +=  "    OMCL_PEPFILES  =  ["
          out += @omcl_pepfiles.collect do |v|
            "['#{v[0]}','#{v[1]}']"
          end.join(",")
          out +=  "]\n"
        end
        out += "}\n"
        puts out
        t = File.new("#{job.job_directory}/config", "w+")
        t.write(out)
        t.close
        t
      end
    end
end
