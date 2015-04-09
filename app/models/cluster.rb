class Cluster < ActiveRecord::Base
    belongs_to :job
    has_and_belongs_to_many :genes
    has_and_belongs_to_many :trees
end
