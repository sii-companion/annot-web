require 'tempfile'

module JobsHelper

  @formatdescs = {:FASTA => { :desc => "Simple sequence text format",
                              :specurl => "http://blast.ncbi.nlm.nih.gov/blastcgihelp.shtml" },
                  :GFF3  => { :desc => "Text-based feature annotation graph format",
                              :specurl => "http://www.sequenceontology.org/gff3.shtml" },
                  :AGP  => { :desc => "Text-based sequence layout format, used for ENA submission",
                              :specurl => "https://www.ncbi.nlm.nih.gov/assembly/agp/AGP_Specification/" },
                  :GAF1  => { :desc => "Genome Ontology Association File, used for GO submission",
                              :specurl => "http://geneontology.org/page/go-annotation-file-gaf-format-10" },
                  :EMBL  => { :desc => "Text-based feature and sequence format, used for ENA submission",
                              :specurl => "http://www.insdc.org/files/feature_table.html" } }

  @fnmaps = {"pseudochr.fasta.gz" => { :title => "Pseudochromosome level genomic sequence", :format => "FASTA" },
            "scafs.fasta.gz" => { :title => "Scaffold level genomic sequence", :format => "FASTA" },
            "pseudo.out.gff3" => { :title => "Pseudochromosome level gene annotations", :format => "GFF3" },
            "scaffold.out.gff3" => { :title => "Scaffold level gene annotations", :format => "GFF3" },
            "pseudo.pseudochr.agp" => { :title => "Pseudochromosome layout", :format => "AGP" },
            "pseudo.scafs.agp" => { :title => "Scaffold layout", :format => "AGP" },
            "out.gaf" => { :title => "Gene Ontology function assignments", :format => "GAF1" },
            "proteins.fasta" => { :title => "Protein sequences", :format => "FASTA"},
            "embl.tar.gz" => { :title => "Pseudochromosome level sequence and annotation", :format => "EMBL"} }

  def file_description(fn)
    if @fnmaps[fn] then
      @fnmaps[fn]
    else
      fn
    end
  end
  module_function :file_description

  def format_description(fn)
    if @formatdescs[fn.to_sym] then
      @formatdescs[fn.to_sym]
    else
      fn
    end
  end
  module_function :format_description

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

    def run_liftoff(val = true)
      @items["run_liftoff"] = val
    end

    def transfer_tool(val)
      @items["transfer_tool"] = val
    end

    def run_braker(val = true)
      @items["run_braker"] = val
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
      @items["ref_dir"] = ref[:referencedir]
      if ref[:snap_model] then
        @items["run_snap"] = "true"
      else
        @items["run_snap"] = "false"
      end
      if ref[:weightfile] then
        @items["WEIGHT_FILE"] = ref[:weightfile]
      end
      if ref[:ncrna_models] then
        @items["NCRNA_MODELS"] = ref[:ncrna_models]
      end
      if ref[:maxintronlen] then
        @items["AUGUSTUS_HINTS_MAXINTRONLEN"] = ref[:maxintronlen]
      end
      if ref[:fix_polycistrons] then
        @items["fix_polycistrons"] = ref[:fix_polycistrons]
      end
      if ref[:do_circos] then
        @items["do_circos"] = ref[:do_circos]
      end
      if ref[:run_braker] then
        @items["run_braker"] = ref[:run_braker]
      end
      if ref[:is_fungi] then
        @items["is_fungi"] = ref[:is_fungi]
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
      add_item("ABACAS_MATCH_SIZE", job[:abacas_match_size])
      add_item("ABACAS_MATCH_SIM", job[:abacas_match_sim])
      add_item("AUGUSTUS_GENEMODEL", 'partial')
      add_item("EMBL_ORGANISM", job[:organism])
      add_item("embl_ena_submission", 'true')
      add_item("truncate_input_headers", 'true')
      add_item("alphanumeric_ids", 'false')
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
      Rails.logger.debug out
      t = File.new("#{job.job_directory}/config", "w+")
      t.write(out)
      t.close
      t
    end
  end
end