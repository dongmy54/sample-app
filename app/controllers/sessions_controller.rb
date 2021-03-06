class SessionsController < ApplicationController
  def new
  end

  def create
    @user = User.find_by(email: params[:session][:email].downcase)
    
    if @user && @user.authenticate(params[:session][:password])
      if @user.activated
        log_in @user
        params[:session][:remember_me] == "1" ? remember(@user) : forget(@user) 
        redirect_back_or @user
      else
        flash[:warning] = "账户未激活，请检查你的邮箱以激活账户。"
        redirect_to root_path
      end
    else
      flash.now[:warning] = "邮箱或者密码无效！" 
      render 'new'
    end 
  end

  def destroy
    logout if logged_in?
    redirect_to root_path
  end

end
