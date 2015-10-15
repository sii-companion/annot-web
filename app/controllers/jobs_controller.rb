class JobsController < ApplicationController
  def new
    # set defaults
    @job = Job.new
    @job[:do_contiguate] = true
    @job[:do_exonerate] = false
    @job[:do_ratt] = true
    @job[:do_pseudo] = true
    @job[:use_transcriptome_data] = false
    @job[:no_resume] = false
    @job[:max_gene_length] = 20000
    @job[:augustus_score_threshold] = 0.8
    @job[:taxon_id] = 5653
    @job[:db_id] = "Companion"
    @job[:ratt_transfer_type] = 'Species'
    @user_file = UserFile.new
  end

  def index
    jobs = Job.all
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

  def create
    @job = Job.create(jobs_params(params))
    if verify_recaptcha(:model => @job, :message => "Oh! It's error with reCAPTCHA!") then
      @job.save
      puts @job.inspect
      # start job and record Sidekiq ID
      jobid = HardWorker.perform_async(@job[:id])
      @job[:job_id] = jobid
      @job.save!
      redirect_to job_path(id: @job[:job_id])
    else
      render 'new'
    end
  end

  def update
    # these do the same
    create
  end

  def destroy
    thisjob = Job.find_by(:job_id => params[:id])
    if thisjob then
      flash[:info] = "Deleted job #{thisjob[:name]}"
      thisjob.destroy
      queue = Sidekiq::Queue.new
      queue.each do |job|
        job.delete if job.jid == params[:id]
      end
      if File.exist?("#{thisjob.job_directory}") then
        FileUtils.rm_rf("#{thisjob.job_directory}")
      end
    end
    render "welcome/index"
  end

  def show
    @job = Job.find_by(:job_id => params[:id])
    if not @job then
      render plain: "job #{params[:id]} not found", status: 404
    else
      @queued = Sidekiq::Status::queued?(params[:id])
      @working = Sidekiq::Status::working?(params[:id])
      @failed = Sidekiq::Status::failed?(params[:id])
      @complete = Sidekiq::Status::complete?(params[:id])
      if @job[:sequence_file_id] then
        @sfile = SequenceFile.find(@job[:sequence_file_id])
      end
      if @job[:transcript_file_id] then
        @tfile = TranscriptFile.find(@job[:transcript_file_id])
      end
      @ref = Reference.find(@job[:reference_id])
    end
  end

  def orths
    job = Job.find_by(:job_id => params[:id])
    if not job then
      render plain: "job #{params[:id]} not found", status: 404
    else
      ref = Reference.find(job[:reference_id])
      cl_a = job.clusters.joins(:genes).where(:genes => {:species => job[:prefix]}).distinct.collect {|c| c[:cluster_id]}
      #cl_a = Cluster.find_by_sql("select * from clusters c join clusters_genes cg on cg.cluster_id = c.id join genes g on g.id = cg.gene_id where c.job_id = '#{job[:id]}' and g.species = '#{job[:prefix]}'")
      cl_b = job.clusters.joins(:genes).where(:genes => {:species => ref[:abbr]}).distinct.collect {|c| c[:cluster_id]}
      #cl_b = Cluster.find_by_sql("select * from clusters c join clusters_genes cg on cg.cluster_id = c.id join genes g on g.id = cg.gene_id where c.job_id = ''#{job[:id]}'' and g.species = '#{ref[:abbr]}'")
      a = cl_a - cl_b
      b = cl_b - cl_a
      ab = cl_a & cl_b
      orths = [{:name => {:A => job[:prefix], :B => ref[:abbr]},
                :data => {:A => a, :B => b, :AB => ab}}]
      render json: orths
    end
  end

  def orths_for_cluster
    clusters = params[:cluster]
    job = Job.find_by(:job_id => params[:id])
    if not job then
      render plain: "job #{params[:id]} not found", status: 404
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

  def get_clusters
    job = Job.find_by(:job_id => params[:id])
    if job and File.exist?("#{job.job_directory}/orthomcl_out") then
      render file: "#{job.job_directory}/orthomcl_out", layout: false, \
        content_type: 'text/plain'
    else
      render plain: "job #{params[:id]} not found", status: 404
    end
  end

  def get_singletons
    job = Job.find_by(:job_id => params[:id])
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
      render plain: "job #{params[:id]} not found", status: 404
    end
  end

  def get_tree
    job = Job.find_by(:job_id => params[:id])
    if job and File.exist?("#{job.job_directory}/tree.out") then
      data = File.open("#{job.job_directory}/tree.out").read
      send_data data, :filename => "#{job[:job_id]}.nwk"
    else
      render plain: "job #{params[:id]} not found or completed", status: 404
    end
  end

  def get_tree_genes
    job = Job.find_by(:job_id => params[:id])
    if job then
      render json: job.tree.genes.order(:product)
    else
      render plain: "job #{params[:id]} not found", status: 404
    end
  end

  private

  def jobs_params(params)
    params.require(:job).permit(:name, :sequence_file_id, :transcript_file_id, \
                                :reference_id, :prefix, :do_pseudo, \
                                :do_contiguate, :do_exonerate, :do_ratt, \
                                :use_transcriptome_data, \
                                :max_gene_length, :augustus_score_threshold, \
                                :taxon_id, :db_id, :ratt_transfer_type, \
                                :no_resume)

  end
end
