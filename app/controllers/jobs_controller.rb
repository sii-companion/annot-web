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
      @job[:no_resume] = false
      @job[:max_gene_length] = 20000
      @job[:augustus_score_threshold] = 0.8
      @job[:taxon_id] = 5653
      @job[:db_id] = "Companion"
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
      @running = 0
      if jobs then
        jobs.each do |job|
          jobname = Sidekiq::Status::get(job[:job_id], :name)
          if not jobname then
            jobname = job[:name]
          end
          @outjobs <<  {:job_id => job[:job_id],
                        :id => job[:id],
                        :created_at => job[:created_at],
                        :started_at => job[:started_at],
                        :finished_at => job[:finished_at],
                        :name => jobname,
                        :queued => Sidekiq::Status::queued?(job[:job_id]),
                        :working => Sidekiq::Status::working?(job[:job_id]),
                        :failed => Sidekiq::Status::failed?(job[:job_id]),
                        :complete => Sidekiq::Status::complete?(job[:job_id])}
          @running = @outjobs.reduce(0) do |a,job|
            if job[:working] then
              a + 1
            else
              a
            end
          end
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

      redirect_to action: "index"
    end
  end

  def destroy
    if not logged_in? then
      redirect_to controller: "sessions", action: "new"
    else
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
  end

  def show
    if not logged_in? then
      redirect_to controller: "sessions", action: "new"
    else
      @job = current_user.jobs.find_by(:job_id => params[:id])
      @queued = Sidekiq::Status::queued?(params[:id])
      @working = Sidekiq::Status::working?(params[:id])
      @failed = Sidekiq::Status::failed?(params[:id])
      @complete = Sidekiq::Status::complete?(params[:id])
      @file = UserFile.find(@job[:user_file_id])
      @ref = Reference.find(@job[:reference_id])
    end
  end

  def orths
    if not logged_in? then
      render plain: "Not logged in. Please log in before using web services.", status: 401
    else
      job = current_user.jobs.find_by(:job_id => params[:id])
      if not job then
        render plain: "job #{params[:id]} not found or completed", status: 404
      else
        ref = Reference.find(job[:reference_id])
        # XXX: this could be made more efficient
        cl_a = job.clusters.joins(:genes).where(:genes => {:species => job[:prefix]}).distinct.collect {|c| c[:cluster_id]}
        cl_b = job.clusters.joins(:genes).where(:genes => {:species => ref[:abbr]}).distinct.collect {|c| c[:cluster_id]}
        a = cl_a - cl_b
        b = cl_b - cl_a
        ab = cl_a & cl_b
        orths = [{:name => {:A => job[:prefix], :B => ref[:abbr]},
                  :data => {:A => a, :B => b, :AB => ab}}]
        render json: orths
      end
    end
  end

  def orths_for_cluster
    if not logged_in? then
      render plain: "Not logged in. Please log in before using web services.", status: 401
    else
      clusters = params[:cluster]
      job = current_user.jobs.find_by(:job_id => params[:id])
      if not job then
        render plain: "job #{params[:id]} not found or completed", status: 404
      else
        ref = Reference.find(job[:reference_id])
        # the code below is horribly hacky IMHO and should eventually be
        # replaced by proper SQL or iterative set operations
        cl_a = job.clusters.joins(:genes).where(:genes => {:species => job[:prefix]}).distinct
        cl_b = job.clusters.joins(:genes).where(:genes => {:species => ref[:abbr]}).distinct
        v = {}
        v[job[:prefix]] = cl_a - cl_b
        v[ref[:abbr]] = cl_b - cl_a
        v["#{job[:prefix]} #{ref[:abbr]}"] = cl_a & cl_b
        results = []
        if not v[clusters] then
          render plain: "clusters #{params[:cluster]} not valid", status: 500
        else
          v[clusters].each do |cl|
            cl.genes.each do |g|
              results << {id: g[:gene_id], product: g[:product], cluster: cl[:cluster_id]}
            end
          end
          respond_to do |format|
            format.html do
              out = []
              results.each do |r|
                out << "#{r[:id]}\t#{r[:product]}\t#{r[:cluster]}"
              end
              render plain: out.join("\n")
            end
            format.json do
              render json: results
            end
          end
        end
      end
    end
  end

  def get_clusters
    if not logged_in? then
      render plain: "Not logged in. Please log in before using web services.", status: 401
    else
      job = current_user.jobs.find_by(:job_id => params[:id])
      if job and File.exist?("#{job.job_directory}/orthomcl_out") then
        render file: "#{job.job_directory}/orthomcl_out", layout: false, \
          content_type: 'text/plain'
      else
        render plain: "job #{params[:id]} not found or completed", status: 404
      end
    end
  end

  def get_singletons
    if not logged_in? then
      render plain: "Not logged in. Please log in before using web services.", status: 401
    else
      job = current_user.jobs.find_by(:job_id => params[:id])
      if job then
        ref = Reference.find(job[:reference_id])
        this_s = job.genes.includes(:clusters).where(:clusters => {id: nil})
        ref_s = Gene.where(job: nil, species: ref[:abbr]).includes(:clusters).where(:clusters => { id: nil})
        respond_to do |format|
          format.html do
            out = []
            results.each do |r|
              out << "#{r[:id]}\t#{r[:product]}\t#{r[:cluster]}"
            end
            render plain: out.join("\n")
          end
          format.json do
            render json: {:ref => ref_s, :this => this_s}
          end
        end
      else
        render plain: "job #{params[:id]} not found or completed", status: 404
      end
    end
  end

  def get_tree
    if not logged_in? then
      render plain: "Not logged in. Please log in before using web services.", status: 401
    else
      job = current_user.jobs.find_by(:job_id => params[:id])
      if job and File.exist?("#{job.job_directory}/tree.out") then
        data = File.open("#{job.job_directory}/tree.out").read
        send_data data, :filename => "#{job[:job_id]}.nwk"
      else
        render plain: "job #{params[:id]} not found or completed", status: 404
      end
    end
  end

  def get_tree_genes
    if not logged_in? then
      render plain: "Not logged in. Please log in before using web services.", status: 401
    else
      job = current_user.jobs.find_by(:job_id => params[:id])
      if job then
        render json: job.tree.genes.order(:product)
      else
        render plain: "job #{params[:id]} not found or completed", status: 404
      end
    end
  end

  private

  def jobs_params(params)
    params.require(:job).permit(:name, :user_file_id, :reference_id, :prefix, \
                                :do_contiguate, :do_exonerate, :do_ratt, \
                                :max_gene_length, :augustus_score_threshold, \
                                :taxon_id, :db_id, :ratt_transfer_type, \
                                :no_resume)

  end
end
