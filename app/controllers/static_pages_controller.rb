class StaticPagesController < ApplicationController
  def faq
    render "faq"
  end

  def survey2018
    render "survey2018"
  end

  def examples
    @job = nil
    @ref = nil
    if CONFIG['example_job_id'] and CONFIG['example_job_id'].length > 0 then
      @job = Job.find_by(:job_id => CONFIG['example_job_id'])
      if @job then
        @ref = Reference.find(@job[:reference_id])
      end
    end
  end

  def how_it_works
    examples
    render "how_it_works"
  end
end
