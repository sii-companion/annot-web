class Gene < ActiveRecord::Base
    belongs_to :job
    belongs_to_many :clusters
    belongs_to_many :trees
end
