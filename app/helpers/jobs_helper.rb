require 'tempfile'

module JobsHelper
  @fnmaps = {"pseudochr.fasta.gz" => "Pseudochromosome level genomic sequence (FASTA)",
            "scafs.fasta.gz" => "Scaffold level genomic sequence (FASTA)",
            "pseudo.out.gff3" => "Pseudochromosome level genes (GFF3)",
            "scaffold.out.gff3" => "Scaffold level genes (GFF3)",
            "pseudo.pseudochr.agp" => "Pseudochromosome layout (AGP)",
            "pseudo.scafs.agp" => "Scaffold layout (AGP)",
            "out.gaf" => "Functional GO annotation (GAF1)",
            "proteins.fasta" => "Protein sequences (FASTA)",
            "embl.tar.gz" => "Pseudochromosome level sequence and annotation (EMBL)"}

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
      @items["CHR_PATTERN"] = "#{prefix}_(%w+)"
      @items["ABACAS_CHR_PREFIX"] = prefix
      @items["ABACAS_SEQ_PREFIX"] = prefix
      @items["ABACAS_BIN_CHR"] = "#{prefix}_00"
    end

    def do_exonerate(val = true)
      @items["run_exonerate"] = val
    end

    def run_snap(val = true)
      @items["run_snap"] = val
    end

    def run_ratt(val = true)
      @items["run_ratt"] = val
    end

    def do_pseudo(val = true)
      @items["do_pseudo"] = val
    end

    def fix_polycistrons(val = true)
      @items["fix_polycistrons"] = val
    end

    def make_embl(val = true)
      @items["make_embl"] = val
    end

    def use_reference(val = true)
      @items["use_reference"] = val
    end

    def do_contiguation(val = true)
      @items["do_contiguation"] = val
    end

    def do_circos(val = true)
      @items["do_circos"] = val
    end

    def select_reference(ref)
      @items["ref_species"] = ref[:abbr]
      #@items["ABACAS_CHR_PATTERN"] = ref[:chromosome_pattern]
      @items["ref_dir"] = ref[:referencedir]
      if ref[:snap_model] then
        @items["run_snap"] = "true"
      else
        @items["run_snap"] = "false"
      end
      if ref[:weightfile] then
        @items["WEIGHT_FILE"] = ref[:weightfile]
      end
      if ref[:maxintronlen] then
        @items["AUGUSTUS_HINTS_MAXINTRONLEN"] = ref[:maxintronlen]
      end
      if ref[:fix_polycistrons] then
        @items["fix_polycistrons"] = ref[:fix_polycistrons]
      end
    end

    def get_target_seq(val)
      target_path = Rails.root.join('public', 'system', 'dragonfly', Rails.env)
      target_path = target_path.join(val[:file_uid])
    end

    def use_target_seq(val)
      target_path = get_target_seq(val)
      unless File.exist?(target_path)
        raise "Target sequence file could not be found!"
      end
      @items["inseq"] = target_path
    end

    def use_transcript_file(val)
      target_path = get_target_seq(val)
      unless File.exist?(target_path)
        raise "Transcript file could not be found!"
      end
      @items["TRANSCRIPT_FILE"] = target_path
    end

    def get_file(job)
      add_item("RATT_TRANSFER_TYPE", job[:ratt_transfer_type])
      add_item("MAX_GENE_LENGTH", job[:max_gene_length])
      add_item("AUGUSTUS_GENEMODEL", 'partial')
      add_item("SPECK_TEMPLATE", "#{CONFIG['rootdir']}/data/speck/companion_html")
      add_item("AUGUSTUS_SCORE_THRESHOLD", job[:augustus_score_threshold].round(2))
      add_item("TAXON_ID", job[:taxon_id])
      add_item("DB_ID", job[:db_id])

      # TODO: add checks for validity and completeness
      out  = "params {\n"
      @items.each do |k,v|
        if v.to_s.match(/^[0-9.]+$/) or v.to_s.match(/^(true|false)$/) then
          out += "    #{k}  =  #{v}\n"
        else
          out += "    #{k}  =  '#{v}'\n"
        end
      end
      out += "}\n"
      logger.debug out
      t = File.new("#{job.job_directory}/config", "w+")
      t.write(out)
      t.close
      t
    end
  end
end