class UserFile < ActiveRecord::Base
  extend Dragonfly::Model
  include Rails.application.routes.url_helpers
  dragonfly_accessor :file
  belongs_to :user
  belongs_to :job
  validates_size_of :file, maximum: 64.megabytes
  validates_property :valid_sequence, of: :file, as: true, message: "is not a valid FASTA, EMBL, or GenBank DNA sequence file."
  validates_property :number_of_sequences, of: :file, in: (0..3000), message: "contains more than 3000 sequences."
  # TODO: need to validate that it is pure DNA sequence
  # TODO: need to validate that headers are correctly formatted
end
