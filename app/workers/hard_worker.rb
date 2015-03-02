class HardWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false, :dead => false
  include Sidekiq::Status::Worker

  def expiration
    @expiration ||= 60*60*24*30*12*15 # keep jobs around for 15 years
  end

  def with_environment(variables={})
    if block_given?
      old_values = variables.map{ |k,v| [k,ENV[k]] }
      begin
         variables.each{ |k,v| ENV[k] = v }
         result = yield
      ensure
        old_values.each{ |k,v| ENV[k] = v }
      end
      result
    else
      variables.each{ |k,v| ENV[k] = v }
    end
  end

  def perform(id)
    job = Job.find(id)
    store name: job[:name]
    store job_id: @jid
    my_stdout = nil
    my_stderr = nil
    status = nil

    job[:started_at] = DateTime.now
    job.save!

    run = "#{CONFIG['nextflowpath']}/nextflow -c " + \
          "#{CONFIG['locationconfig']} -c " + \
          "/Users/ss34/develop/annot-nf/params_default.config run " + \
          "#{CONFIG['nextflowscript']} #{CONFIG['dockerconf']} -resume"

    with_environment("ROOTDIR" => "#{CONFIG['rootdir']}") do
      status = Open4::popen4(run) do |pid, stdin, stdout, stderr|
        my_stdout = stdout.readlines.join
        my_stderr = stderr.readlines.join
      end
    end

    puts my_stdout

    job[:finished_at] = DateTime.now
    job.save!

    if (not status) or status.exitstatus != 0 then
      raise "run failed"
    end
  end
end