class UserFilesController < ApplicationController
  def index
    @user_files = current_user.user_files
    @user_file = UserFile.new
    render :action => "new"
  end

  def new
    @user_file = UserFile.new
    @user_files = current_user.user_files
  end

  def create_for_jobform
    respond_to do |format|
      @user_file = UserFile.new(file_params)
      @user_file.user = current_user
      if @user_file.save then
        @user_file.file.canonicalize_seq!
      end
      format.js { render 'jobs/user_file_line'}
    end
  end

  def create
    respond_to do |format|
      @user_file = UserFile.new(file_params)
      @user_file.user = current_user
      if @user_file.save then
        @user_file.file.canonicalize_seq!
      end
      format.html { redirect_to new_user_file_path }
      format.js
    end
  end

  def destroy
    thisfile = UserFile.find(params[:id])
    if thisfile then
      thisfile.destroy
    end
    redirect_to action: "new"
  end

  private

  def file_params
    params.require(:user_file).permit(:file)
  end
end