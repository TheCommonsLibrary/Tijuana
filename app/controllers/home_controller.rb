class HomeController < ApplicationController
  include RemarketingHelper

  def index
    @user = User.new
    @secure_user = cookies.signed[:user_id] && User.find_by_id(cookies.signed[:user_id])
    render :action => "index"
  end

  def subscribe
    begin
      subscribe_if_valid(params)
    rescue ActiveRecord::RecordNotUnique
      redirect_to_welcome_page
    end
  end

  def robots
    respond_to :text
    expires_in 24.hours, public: true
  end

  protected

  def homepage
    @homepage ||= Homepage.first
  end

  helper_method :homepage

  private

  def subscribe_if_valid(params)
    email_has_value = params[:user] && params[:user][:email]
    @user = User.new(:email => params[:user][:email])
    if email_has_value && @user.save_with_source('homepage')
      UserMailer.welcome_to_getup(@user)
      redirect_to_welcome_page
    else
      @homepage = Homepage.first
      redirect_to '/'
    end
  end

  def redirect_to_welcome_page
    redirect_to "/membership/welcome-to-getup"
  end
end
