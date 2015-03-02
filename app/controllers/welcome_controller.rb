require 'sidekiq/api'

class WelcomeController < ApplicationController
  def index
    workers = Sidekiq::Workers.new
    @content = []
    workers.each do |name, work|
        # name is a unique identifier per Processor instance
        # work is a Hash which looks like:
        # { 'queue' => name, 'run_at' => timestamp, 'payload' => msg }
      @content << [name, work['run_at']]
    end
  end
end
