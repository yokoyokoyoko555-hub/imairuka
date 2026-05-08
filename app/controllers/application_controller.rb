class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # モックアップ用に認証を無効化
  before_action :require_login

  before_action :set_company_info

  # private

  def require_login
    unless session[:user_id]
      redirect_to login_path, alert: "ログインが必要です"
    end
  end

  private

  def set_company_info
    @company = Company.first || Company.new
  end

  def current_user
    if session[:user_id]
      @current_user ||= User.find_by(id: session[:user_id])
    elsif cookies.signed[:user_id] && cookies[:remember_token]
      user = User.find_by(id: cookies.signed[:user_id])
      if user&.authenticated?(cookies[:remember_token])
        session[:user_id] = user.id
        @current_user = user
      end
    end
  end
end
