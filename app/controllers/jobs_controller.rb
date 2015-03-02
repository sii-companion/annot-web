class JobsController < ApplicationController
  def new
    if not logged_in? then
      redirect_to controller: "sessions", action: "new"
    else
      @job = Job.new
      @user_file = UserFile.new
    end
  end

  def index
    if not logged_in? then
      redirect_to controller: "sessions", action: "new"
    else
      jobs = current_user.jobs
      @outjobs = []
      puts @outjobs
      if jobs then
        jobs.each do |job|
          data = Sidekiq::Status::get_all job[:job_id]
          @outjobs <<  {:job_id => job[:job_id],
                        :id => job[:id],
                        :created_at => job[:created_at],
                        :started_at => Sidekiq::Status::get(job[:job_id], :started_at),
                        :finished_at => Sidekiq::Status::get(job[:job_id], :finished_at),
                        :name => Sidekiq::Status::get(job[:job_id], :name),
                        :queued => Sidekiq::Status::queued?(job[:job_id]),
                        :working => Sidekiq::Status::working?(job[:job_id]),
                        :failed => Sidekiq::Status::failed?(job[:job_id]),
                        :complete => Sidekiq::Status::complete?(job[:job_id])}
        end
      end
    end
  end

  def create
    if not logged_in? then
      redirect_to controller: "sessions", action: "new"
    else
      @job = Job.create(jobs_params(params))
      @job.user = current_user
      @job.save!
      jobid = HardWorker.perform_async(@job[:id])
      @job[:job_id] = jobid
      @job.save!
      redirect_to action: "index"
    end
  end

  def destroy
    thisjob = current_user.jobs.find_by(:job_id => params[:id])
    if thisjob then
      thisjob.destroy
      queue = Sidekiq::Queue.new
      queue.each do |job|
        job.delete if job.jid == params[:id]
      end
    end
    redirect_to action: "index"
  end

  def show
    @job = current_user.jobs.find_by(:job_id => params[:id])
  end

  private

  def jobs_params(params)
    params.require(:job).permit(:name, :user_file_id, :reference_id)

  end
end
