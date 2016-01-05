class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
  end

  def new
    if params[:user] then
      @user = params[:user]
    else
      @user = User.new
    end
    render :signup
  end

  def create
    @user = User.new(params.require(:user).permit(:name, :email, :fullname,
                                                  :institution, :password,
                                                  :password_confirmation))
    if @user.save
      log_in @user
      redirect_to :jobs
    else
      render :signup
    end
  end
end
