class Gene < ActiveRecord::Base
    belongs_to :job
    has_and_belongs_to_many :clusters
    has_and_belongs_to_many :trees
end
