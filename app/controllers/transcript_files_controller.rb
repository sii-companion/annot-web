class TranscriptFilesController < ApplicationController
  def index
    if not logged_in? then
      redirect_to controller: "sessions", action: "new"
    else
      @transcript_files = current_user.transcript_files
      @transcript_file = TranscriptFile.new
      render :action => "new"
    end
  end

  def new
    if not logged_in? then
      redirect_to controller: "sessions", action: "new"
    else
      @transcript_file = TranscriptFile.new
      @transcript_files = current_user.transcript_files
    end
  end

  def create_for_jobform
    if not logged_in? then
      redirect_to controller: "sessions", action: "new"
    else
      respond_to do |format|
        @transcript_file = TranscriptFile.new(file_params)
        @transcript_file.user = current_user
        @transcript_file.save
        format.js { render 'jobs/trans_file_line'}
      end
    end
  end

  def create
    if not logged_in? then
      redirect_to controller: "sessions", action: "new"
    else
      respond_to do |format|
        @transcript_file = TranscriptFile.new(file_params)
        @transcript_file.user = current_user
        @transcript_file.save
        format.html { redirect_to new_transcript_file_path }
        format.js
      end
    end
  end

  def destroy
    if not logged_in? then
      redirect_to controller: "sessions", action: "new"
    else
      thisfile = TranscriptFile.find(params[:id])
      if thisfile then
        thisfile.destroy
      end
      redirect_to action: "new"
    end
  end

  private

  def file_params
    params.require(:transcript_file).permit(:file)
  end
end