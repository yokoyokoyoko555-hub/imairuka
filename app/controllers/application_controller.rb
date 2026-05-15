class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :require_login
  before_action :ensure_current_company_available
  before_action :prevent_read_only_write
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

  def ensure_current_company_available
    return unless current_user
    return if current_user.platform_admin?
    return if current_company&.service_available?

    reset_login_state
    redirect_to login_path, alert: "契約状態により現在は利用できません。運営までお問い合わせください。"
  end

  def prevent_read_only_write
    return unless current_user&.read_only?
    return if request.get? || request.head?
    return if controller_name == "sessions" && action_name == "destroy"

    redirect_back fallback_location: root_path, alert: "閲覧のみのアカウントでは更新操作はできません。"
  end

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

  def reset_login_state
    current_user&.forget
    session[:user_id] = nil
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
    @current_user = nil
    @current_company = nil
  end
end
