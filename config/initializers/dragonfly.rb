require 'dragonfly'

class GFF3Analyser
  def call(content)
    path = content.path
    rval = system("gt gff3 -retainids -tidy -show no #{path}")
    Rails.logger.info "GFF3 is valid: " + rval.to_s
    rval
  end
end

class TranscriptGTFAnalyser
  def call(content)
    valid = true
    seen_exon = false
    path = content.path
    File.open(path, 'r').each_line  do |l|
      next if l[0] == "#"
      seqid, src, type, start, stop, score, strand, phase, attribs = l.split("\t")
      if attribs.nil? then
        return false
      end
      if not seen_exon and type == 'exon' then
        seen_exon = true
      end
      if not /[-+.?]/.match(strand) then
        return false
      end
      if not /[0-3]./.match(phase) then
        return false
      end
      begin
        if start.to_i > stop.to_i then
            return false
        end
      rescue
        return false
      end
      if not /gene_id ['"].+['"];?/.match(attribs) then
        return false
      end
      if not /transcript_id ['"].+['"];?/.match(attribs) then
        return false
      end
    end
    if not seen_exon then
      valid = false
    end
    return valid
  end
end

class SequenceValidAnalyser
  def call(content)
    path = content.path
    rval = system("gt convertseq -noseq #{path}")
    Rails.logger.info "sequence #{path} is valid: #{rval.to_s}"
    rval
  end
end

class SequenceNumberAnalyser
  def call(content)
    path = content.path
    rval = `gt seqstat -contigs #{path}`
    m = rval.match(/number of contigs:\s+(\d+)/)
    nof_contigs = 0
    if m then
      nof_contigs = m[1].to_i
    end
    return nof_contigs
  end
end

Dragonfly.app.configure do
  plugin :imagemagick
  secret "b2909acc0dbe34c4a88d89c8c465f0f45b4a7b1d4e0a957b3181e6ac1063e2d3"
  response_header "Cache-Control", "public, max-age=2592000"

  url_format "/media/:job/:name"

  datastore :file,
    root_path: Rails.root.join('public/system/dragonfly', Rails.env),
    server_root: Rails.root.join('public')

  processor :canonicalize_gff3 do |content|
    content.shell_update do |old_path, new_path|
      "gt gff3 -o #{new_path} -force -retainids -fixregionboundaries -tidy -retainids #{old_path}"
    end
  end

  processor :canonicalize_seq do |content|
    content.shell_update ext: 'fasta' do |old_path, new_path|
      "gt convertseq -force -o #{new_path} #{old_path}"
    end
  end

  analyser :valid_gff3, GFF3Analyser.new
  analyser :valid_transcript, TranscriptGTFAnalyser.new
  analyser :valid_sequence, SequenceValidAnalyser.new
  analyser :number_of_sequences, SequenceNumberAnalyser.new
end

# Logger
Dragonfly.logger = Rails.logger

# Mount as middleware
Rails.application.middleware.use Dragonfly::Middleware

# Add model functionality
if defined?(ActiveRecord::Base)
  ActiveRecord::Base.extend Dragonfly::Model
  ActiveRecord::Base.extend Dragonfly::Model::Validations
end
