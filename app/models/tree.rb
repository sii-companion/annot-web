class Tree < ActiveRecord::Base
    extend Dragonfly::Model
    dragonfly_accessor :seq
    belongs_to :job
    has_many :genes
end
