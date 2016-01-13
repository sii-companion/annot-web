MEGABYTE = 1024.0 * 1024.0

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include SessionsHelper
  include Sys

  before_filter :number_of_jobs, :check_closed

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

  def check_closed
    if File.exist?(Rails.root.join('CLOSED')) then
      @closed = true
      return
    end
    if not CONFIG['min_work_space'] then
      @closed = false
    else
      begin
        stat = Filesystem.stat(CONFIG['workdir'])
        if ((stat.block_size*stat.blocks_available) / MEGABYTE) < CONFIG['min_work_space'].to_i then
          @closed = true
        else
          @closed = false
        end
      rescue
        @closed = false
      end
    end
  end
end