class Gene < ActiveRecord::Base
    belongs_to :job
    has_and_belongs_to_many :clusters
    has_and_belongs_to_many :trees
    validates :gene_id, uniqueness: { scope: :species }, if: :reference_gene?
    validates :gene_id, uniqueness: { scope: [:species, :job_id] }, unless: :reference_gene?

    def reference_gene?
        job_id.nil?
    end
end
