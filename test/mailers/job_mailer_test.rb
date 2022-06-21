require 'minitest/mock'
require 'test_helper'

class JobMailerTest < ActionMailer::TestCase

  setup do
    @job = Job.first
    @gstat = GenomeStat.new
    @job.genome_stat = @gstat
    @job.email = "test@test"
    @ref = Reference.new
    @ref[:nof_genes] = 100
  end

  test "should send success email with 20% lower genes warning" do  
    @gstat[:nof_genes] = 70
    @gstat[:nof_pseudogenes] = 0    
    
    Reference.stub :find, @ref do
      assert_emails 1 do
        JobMailer.finish_success_job_email(@job).deliver_now    
      end
      email = ActionMailer::Base.deliveries.last
      assert_match "Number of genes is 20% lower", email.body.to_s
    end
  end

  test "should send success email with 20% greater genes warning" do
    @gstat[:nof_genes] = 130
    @gstat[:nof_pseudogenes] = 0    
    
    Reference.stub :find, @ref do
      assert_emails 1 do
        JobMailer.finish_success_job_email(@job).deliver_now    
      end
      email = ActionMailer::Base.deliveries.last
      assert_match "Number of genes is 20% greater", email.body.to_s
    end
  end

  test "should send success email with pseudogene warning" do
    @gstat[:nof_pseudogenes] = 20
    @gstat[:nof_genes] = 100

    Reference.stub :find, @ref do
      assert_emails 1 do
        JobMailer.finish_success_job_email(@job).deliver_now    
      end
      email = ActionMailer::Base.deliveries.last
      assert_match "Number of pseudogenes exceeded 10%", email.body.to_s
    end
  end
  
end
