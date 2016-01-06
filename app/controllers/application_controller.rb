class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include SessionsHelper

  before_filter :number_of_jobs

  def number_of_jobs
    @n_working = 0
    @n_queued = 0
    jobs = Job.where("finished_at is NULL")
    if jobs then
        jobs.each do |job|
            if Sidekiq::Status::queued?(job[:job_id]) then
                @n_queued = @n_queued + 1
            elsif Sidekiq::Status::working?(job[:job_id]) then
                @n_working = @n_working + 1
            end
        end
    end
  end
end