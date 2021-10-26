class SequenceFile < UserFile
  validates_property :valid_sequence, of: :file, as: true, message: "is not a valid DNA sequence file."
  validates_property :number_of_sequences, of: :file, in: (0..30000), message: "contains more than 30000 sequences."
  # TODO: need to validate that it is pure DNA sequence
  # TODO: need to validate that headers are correctly formatted
end
