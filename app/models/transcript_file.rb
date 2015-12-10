class TranscriptFile < UserFile
  validates_property :valid_transcript, of: :file, as: true, message: "is not a GTF file in the correct format or does not contain any exon features."
end
