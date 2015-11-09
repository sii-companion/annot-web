class UserFile < ActiveRecord::Base
  extend Dragonfly::Model
  include Rails.application.routes.url_helpers
  dragonfly_accessor :file
  belongs_to :job
  validates_size_of :file, maximum: 64.megabytes
end
