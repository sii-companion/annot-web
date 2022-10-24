class SequenceFile < UserFile
  validates_property :number_of_sequences, of: :file, in: (0..4000), message: "contains more than 4000 sequences."
  validates_property :valid_dna_bases, of: :file, as: true, message: "contains invalid DNA bases."
  # TODO: need to validate that headers are correctly formatted
end
