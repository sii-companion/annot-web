class JobsController < ApplicationController
  def new
    if not logged_in? then
      redirect_to controller: "sessions", action: "new"
    else
      # set defaults
      @job = Job.new
      @job[:do_contiguate] = true
      @job[:do_exonerate] = false
      @job[:do_ratt] = true
      @job[:max_gene_length] = 20000
      @job[:augustus_score_threshold] = 0.8
      @job[:taxon_id] = 5653                    # 'Kinetoplastida'
      @job[:db_id] = "Kingpin"
      @job[:ratt_transfer_type] = 'Species'
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
          @outjobs <<  {:job_id => job[:job_id],
                        :id => job[:id],
                        :created_at => job[:created_at],
                        :started_at => job[:started_at],
                        :finished_at => job[:finished_at],
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
      @job.save
      puts @job.inspect

      # start job and record Sidekiq ID
      jobid = HardWorker.perform_async(@job[:id])
      @job[:job_id] = jobid
      @job.save!

      # send notification email
      #UserMailer.welcome_email(current_user).deliver_later

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
    @queued = Sidekiq::Status::queued?(params[:id])
    @working = Sidekiq::Status::working?(params[:id])
    @failed = Sidekiq::Status::failed?(params[:id])
    @complete = Sidekiq::Status::complete?(params[:id])
    @file = UserFile.find(@job[:user_file_id])
    @ref = Reference.find(@job[:reference_id])
  end

  def orths
    job = current_user.jobs.find_by(:job_id => params[:id])
    ref = Reference.find(job[:reference_id])

    nof_a = 0
    nof_b = 0
    nof_ab = 0

    File.open("#{job.job_directory}/orthomcl_out").each_line do |l|
      m = l.match(/^(ORTHOMCL[0-9]+)/)
      in_a = false
      in_b = false
      if m and l.match(/\(#{job[:prefix]}\)/) then
        in_a = true
      end
      if m and l.match(/\(#{ref[:abbr]}\)/) then
        in_b = true
      end
      if in_a and in_b then
        nof_ab += 1
      elsif in_a then
        nof_a += 1
      elsif in_b then
        nof_b += 1
      end
    end
    orths = [{:name => {:A => job[:prefix], :B => ref[:abbr]},
              :values => {:A => nof_a, :B => nof_b, :AB => nof_ab}}]
    render json: orths
  end

  private

  def jobs_params(params)
    params.require(:job).permit(:name, :user_file_id, :reference_id, :prefix, \
                                :do_contiguate, :do_exonerate, :do_ratt, \
                                :max_gene_length, :augustus_score_threshold, \
                                :taxon_id, :db_id, :ratt_transfer_type)

  end
end
