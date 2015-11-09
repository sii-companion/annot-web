class JobMailer < ApplicationMailer
  default from: 'ss34@sanger.ac.uk'

  def start_job_email(job)
    @url = jobs_url(:only_path => :true)
    @job = job
    mail(to: @job.email, subject: "Your job '#{job[:name]}' has started running")
  end

  def finish_success_job_email(user, job)
    @url = jobs_url(:only_path => :true)
    @job = job
    mail(to: @job.email, subject: "Your job '#{job[:name]}' has finished successfully")
  end

  def finish_failure_job_email(user, job)
    @url = jobs_url(:only_path => :true)
    @job = job
    mail(to: @job.email, subject: "Your job '#{job[:name]}' has failed")
  end
end