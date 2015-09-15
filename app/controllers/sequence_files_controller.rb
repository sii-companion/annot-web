class SequenceFilesController < ApplicationController
  def index
    if not logged_in? then
      redirect_to controller: "sessions", action: "new"
    else
      @sequence_files = current_user.sequence_files
      @sequence_file = SequenceFile.new
      render :action => "new"
    end
  end

  def new
    if not logged_in? then
      redirect_to controller: "sessions", action: "new"
    else
      @sequence_file = SequenceFile.new
      @sequence_files = current_user.sequence_files
    end
  end

  def create_for_jobform
    if not logged_in? then
      redirect_to controller: "sessions", action: "new"
    else
      respond_to do |format|
        @sequence_file = SequenceFile.new(file_params)
        @sequence_file.user = current_user
        if @sequence_file.save then
          @sequence_file.file.canonicalize_seq!
        end
        format.js { render 'jobs/seq_file_line'}
      end
    end
  end

  def create
    if not logged_in? then
      redirect_to controller: "sessions", action: "new"
    else
      respond_to do |format|
        @sequence_file = SequenceFile.new(file_params)
        @sequence_file.user = current_user
        format.html { redirect_to new_sequence_file_path }
        format.js
      end
    end
  end

  def destroy
    if not logged_in? then
      redirect_to controller: "sessions", action: "new"
    else
      thisfile = SequenceFile.find(params[:id])
      if thisfile then
        thisfile.destroy
      end
      redirect_to action: "new"
    end
  end

  private

  def file_params
    params.require(:sequence_file).permit(:file)
  end
end