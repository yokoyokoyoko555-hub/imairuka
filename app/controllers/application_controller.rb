class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :require_login
  before_action :set_current_context
  before_action :set_company_info

  helper_method :current_user, :current_company

  def require_login
    return if current_user

    redirect_to login_path, alert: "ログインが必要です"
  end

  def current_user
    if session[:user_id]
      @current_user ||= User.active.includes(:company).find_by(id: session[:user_id])
    elsif cookies.signed[:user_id] && cookies[:remember_token]
      user = User.active.includes(:company).find_by(id: cookies.signed[:user_id])
      if user&.authenticated?(cookies[:remember_token])
        session[:user_id] = user.id
        @current_user = user
      end
    end
  end

  def current_company
    @current_company ||= current_user&.company || Company.first
  end

  private

  def set_current_context
    Current.user = current_user
    Current.company = current_company
  end

  def set_company_info
    @company = current_company || Company.new
  end

  def require_role!(*roles)
    return if current_user && roles.map(&:to_s).include?(current_user.role)

    redirect_to root_path, alert: "この操作を行う権限がありません"
  end
end
