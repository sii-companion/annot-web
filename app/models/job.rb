class Job < ActiveRecord::Base
    belongs_to :user
    has_one :user_file
    has_one :reference
end
