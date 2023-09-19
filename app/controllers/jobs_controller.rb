class JobsController < ApplicationController
  helper_method :sort_column, :sort_direction

  def sort_column
    params.include?(:sort) ? params[:sort] : "created_at"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end

  def new
    flash[:info] = "This is an enhanced release of Companion that includes integration with tools " \
                    "such as BRAKER2 and Liftoff. " \
                    "If you should encounter any issues when running your job, please try again on " \
                    "<a class=\"alert-link\" href=\"https://companion.ac.uk/\">another server</a>."
    if @closed then
      flash[:info] = "New job creation is temporarily closed for technical " + \
                     "reasons."
      redirect_to :welcome
    else
      # set defaults
      @job = Job.new
      @job[:do_contiguate] = true
      @job[:do_exonerate] = false
      @job[:transfer_tool] = "liftoff"
      @job[:run_braker] = true
      @job[:do_pseudo] = true
      @job[:use_transcriptome_data] = false
      @job[:no_resume] = false
      @job[:max_gene_length] = 50000
      @job[:max_overlap] = 5
      @job[:abacas_match_size] = 500
      @job[:abacas_match_sim] = 85
      @job[:augustus_score_threshold] = 0.4
      @job[:taxon_id] = CONFIG['taxon']['id']
      @job[:db_id ] = "Companion"
      @job[:ratt_transfer_type] = 'Species'
      @job.build_sequence_file
      @job.build_transcript_file
    end
  end

  def index
    if !logged_in? then
      flash[:info] = "You do not have permission to view all jobs in the " + \
                     "queue. Please access your job using the URL you were " + \
                     "given or by searching for your job ID."
      redirect_to :welcome
    else
      jobs = Job.all.order(sort_column + " " + sort_direction)
      @outjobs = []
      @running = 0
      if jobs then
        jobs.each do |job|
          if params[:status] then
            status = params[:status][:type]
            if !status.empty? then
              if (Sidekiq::Status::working?(job[:job_id]) && status != "working") then
                next
              elsif (Sidekiq::Status::complete?(job[:job_id]) && status != "completed") then
                next
              elsif (Sidekiq::Status::failed?(job[:job_id]) && status != "failed") then
                next
              elsif (Sidekiq::Status::queued?(job[:job_id]) && status != "queued") then
                next
              end
            end
          end
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
                        :email => job[:email],
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
    @job = Job.new(jobs_params(params))
    if simple_captcha_valid? && @job.save(validate: false) then
      Rails.logger.info @job.inspect
      file = @job.sequence_file
      if file.file.valid_sequence
        file.file.canonicalize_seq!
        if @job.valid?
          # start job and record Sidekiq ID
          jobid = HardWorker.perform_async(@job[:id])
          @job[:job_id] = jobid
          @job.save!
          url = Rails.application.routes.url_helpers.job_url(id: @job[:job_id], :host => request.host_with_port)
          flash[:success] = "Your job with ID <b>#{jobid}</b> has just been successfully
              created and enqueued. You can go back to this page and check the
              status of your job using the following URL:
              <a href=\"#{url}\">#{url}</a>."
          redirect_to job_path(id: @job[:job_id])
        else
          render 'new'
        end
      else
        flash[:info] = "Not a valid DNA sequence file."
      end
    else
      flash[:info] = "Invalid human verification code. Please try again."
      render 'new'
    end
  end

  def restart
    @job = Job.find_by(:job_id => params[:id])
    if @job.valid?
      jobid = HardWorker.perform_async(@job[:id])
      @job[:job_id] = jobid
      @job[:finished_at] = nil
      @job.save!
      url = Rails.application.routes.url_helpers.job_url(id: @job[:job_id], :host => request.host_with_port)
      redirect_to :jobs
    end
  end

  def stop
    @job = Job.find_by(:job_id => params[:id])
    if @job.valid?
      HardWorker.cancel!(@job[:job_id])
      redirect_to :jobs
    end
  end

  def destroy
    if !logged_in? then
      flash[:info] = "You do not have permission to delete jobs in the " + \
                     "queue."
      redirect_to :welcome
    elsif CONFIG['example_job_id'] == params[:id] then
      flash[:info] = "Can't delete the example job. Remove the job from " + \
                      "the configuration to allow deletion."
      redirect_to :jobs
    else
      thisjob = Job.find_by(:job_id => params[:id])
      if thisjob then
        thisjob.delete
        flash[:info] = "Job '#{thisjob[:name]}' was deleted."
      end
      if logged_in? then
        redirect_to :jobs
      else
        redirect_to "welcome/index"
      end
    end
  end

  def bulk_destroy
    if !logged_in? then
      flash[:info] = "You do not have permission to delete jobs in the " + \
                     "queue."
      redirect_to :welcome
    else
      if params[:collection_ids] then
        jobs = Job.where(id: params[:collection_ids])
        job_ids_to_delete = jobs.pluck(:job_id)
        jobs.each do |job|
          job.delete
        end
        flash[:info] = "Deleted job(s) #{job_ids_to_delete.join(", ")}."
      else
        flash[:info] = "No job(s) selected."
      end
      redirect_to :jobs
    end
  end

  def show
    @job = Job.find_by(:job_id => params[:id])
    if not @job then
      flash.now[:danger] = "The job with ID '#{params[:id]}' could not be found."
      render "welcome/index" , status: 404
    else
      @job_hash = {:queued => Sidekiq::Status::queued?(@job[:job_id]),
                   :working => Sidekiq::Status::working?(@job[:job_id]),
                   :failed => Sidekiq::Status::failed?(@job[:job_id]),
                   :complete => Sidekiq::Status::complete?(@job[:job_id])}
      @ref = Reference.find(@job[:reference_id]) rescue Reference.new
      if @job_hash[:failed] then
        render 'jobs/show_failed'
      elsif @job_hash[:complete] and (!@job.genome_stat or @job.genome_stat[:nof_genes] == 0) then
        render 'jobs/show_empty'
      else
        render 'jobs/show'
      end
    end
  end

  def orths
    job = Job.find_by(:job_id => params[:id])
    expires_in 1.month, :public => true
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
    expires_in 1.month, :public => true
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
        render plain: "cluster #{params[:cluster]} not valid", status: 500
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
    expires_in 1.month, :public => true
    if job and File.exist?("#{job.job_directory}/orthomcl_out") then
      render file: "#{job.job_directory}/orthomcl_out", layout: false, \
        content_type: 'text/plain'
    else
      render plain: "job #{params[:id]} not found", status: 404
    end
  end

  def get_singletons
    job = Job.find_by(:job_id => params[:id])
    expires_in 1.month, :public => true
    if job then
      ref = Reference.find(job[:reference_id])
      this_s = job.genes.includes(:clusters).where(:clusters => {id: nil}, :gtype => 'coding')
      #ref_s = Gene.where(job: nil, species: ref[:abbr]).includes(:clusters).where(:clusters => { id: nil})
      ref_s = Gene.where(species: ref[:abbr], :gtype => 'coding') -
       Gene.joins('JOIN clusters_genes ON genes.id = clusters_genes.gene_id ' + \
                  'JOIN clusters ON clusters_genes.cluster_id = clusters.id')
           .where('genes.species = ? and clusters.job_id = ?', ref[:abbr], job[:id])
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
    expires_in 1.month, :public => true
    if job and File.exist?("#{job.job_directory}/tree.out") then
      data = File.open("#{job.job_directory}/tree.out").read
      send_data data, :filename => "#{job[:job_id]}.nwk"
    else
      render plain: "job #{params[:id]} not found or completed", status: 404
    end
  end

  def get_report
    job = Job.find_by(:job_id => params[:id])
    expires_in 1.month, :public => true
    if job then
      if File.exist?("#{job.job_directory}/pseudo.report.html") then
        data = File.open("#{job.job_directory}/pseudo.report.html").read
        send_data data, :filename => "#{job[:job_id]}.pseudo.report.html"
      else
        render html: "No report found for this job."
      end
    else
      render plain: "job #{params[:id]} not found or completed", status: 404
    end
  end

  def get_tree_genes
    job = Job.find_by(:job_id => params[:id])
    expires_in 1.month, :public => true
    if job then
      render json: job.tree.genes.order(:product)
    else
      render plain: "job #{params[:id]} not found", status: 404
    end
  end

  def get_all_synteny_images
    job = Job.find_by(:job_id => params[:id])
    if job then
      if job.circos_images and job.circos_images.size > 0 then
        t = Tempfile.new(job.job_id)
        Zip::OutputStream.open(t.path) do |zos|
          job.circos_images.each do |image|
            zos.put_next_entry("#{image.chromosome}.png")
            zos.print IO.read(image.file.path)
          end
        end
        send_file t.path, :type => 'application/zip',
                          :disposition => 'attachment',
                          :filename => "#{job.name.parameterize}.zip"
        t.close
      else
        render html: "No synteny plots found for this job."
      end
    else
      render plain: "job #{params[:id]} not found or completed", status: 404
    end
  end

  def get_all_result_files
    job = Job.find_by(:job_id => params[:id])
    if job then
      if job.result_files and job.result_files.size > 0 then
        t = Tempfile.new(job.job_id)
        Zip::OutputStream.open(t.path) do |zos|
          job.result_files.sort.each do |rf|
            zos.put_next_entry("#{rf.file.name}")
            zos.print IO.read(rf.file.path)
          end
        end
        send_file t.path, :type => 'application/zip',
                          :disposition => 'attachment',
                          :filename => "#{job.name.parameterize}_results.zip"
        t.close
      end
    end
  end

  private

  def jobs_params(params)
    params.require(:job).permit(:name, :sequence_file, :transcript_file_id, \
                                :reference_id, :prefix, :do_pseudo, \
                                :do_contiguate, :do_exonerate, :run_braker, \
                                :transfer_tool, :use_transcriptome_data, :organism, \
                                :max_gene_length, :max_overlap, \
                                :augustus_score_threshold , \
                                :abacas_match_size, :abacas_match_sim, \
                                :taxon_id, :db_id, :ratt_transfer_type, \
                                :no_resume, :email, sequence_file_attributes: [:id, :file],
                                transcript_file_attributes: [:id, :file])

  end
end
