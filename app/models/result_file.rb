class ResultFile < ActiveRecord::Base
  extend Dragonfly::Model
  include Rails.application.routes.url_helpers
  dragonfly_accessor :file
  belongs_to :job
end
