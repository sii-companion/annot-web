require 'test_helper'
require_relative '../lib/job_outputs'

class JobOutputsTest < ActiveSupport::TestCase
    include JobOutputs

    test "Leptomonas pyrrhocoris transcripts should match" do
        assert_match "LpyrH10_01_0470", match_gene_id("rna_LpyrH10_01_0470_1")
        assert_match "LpyrH10_01_0470", match_gene_id("rna_LpyrH10_01_0470")
    end

    test "Leishmania infantum transcripts should match" do
        assert_match "LINF_170006200", match_gene_id("LINF_170006200_T1")
    end

    test "Eimeria tenella Houghton transcripts should match" do
        assert_match "ETH2_1595900", match_gene_id("ETH2_1595900_mRNA1")
    end
end
