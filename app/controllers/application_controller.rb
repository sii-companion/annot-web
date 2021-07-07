MEGABYTE = 1024.0 * 1024.0

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include SessionsHelper
  include Sys
  include SimpleCaptcha::ControllerHelpers

  before_filter :number_of_jobs, :check_closed

  def number_of_jobs
    @n_working = 0
    @n_queued = 0
    jobs = Job.where("finished_at is NULL")
    if jobs then
        jobs.each do |job|
            if Sidekiq::Status::working?(job[:job_id]) then
                @n_working = @n_working + 1
            elsif not Sidekiq::Status::failed?(job[:job_id]) then
                @n_queued = @n_queued + 1
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

  private

  def get_jira_client
    # add any extra configuration options for your instance of JIRA,
    # e.g. :use_ssl, :ssl_verify_mode, :context_path, :site
    options = {
      :username => CONFIG['jira_api_user'],
      :password => CONFIG['jira_api_token'],
      :site     => 'https://glasgow-iii.atlassian.net/',
      :context_path => '', # often blank
      :auth_type => :basic,
      :read_timeout => 120
    }
    @jira_client = JIRA::Client.new(options)
  end
end
