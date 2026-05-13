class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create, :destroy]
  skip_before_action :ensure_current_company_available, only: [:new, :create, :destroy]

  layout "auth"

  def new
    redirect_to root_path if current_user
  end

  def create
    if current_user
      redirect_to root_path
      return
    end

    user = User.active.includes(:company).find_by(email: params[:email].to_s.strip.downcase)

    if user&.authenticate(params[:password])
      unless user.platform_admin? || user.company&.service_available?
        flash.now[:alert] = "契約状態により現在は利用できません。運営までお問い合わせください。"
        render :new, status: :forbidden
        return
      end

      session[:user_id] = user.id
      user.update!(last_login_at: Time.current)
      remember_user(user)
      redirect_to root_path, notice: "ログインしました"
    else
      flash.now[:alert] = "メールアドレスまたはパスワードが正しくありません"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_login_state
    redirect_to login_path, notice: "ログアウトしました"
  end

  private

  def remember_user(user)
    if params[:remember_me] == "1"
      user.remember
      cookies.permanent.signed[:user_id] = {
        value: user.id,
        secure: Rails.env.production?,
        same_site: :lax
      }
      cookies.permanent[:remember_token] = {
        value: user.remember_token,
        secure: Rails.env.production?,
        same_site: :lax
      }
    else
      user.forget
      cookies.delete(:user_id)
      cookies.delete(:remember_token)
    end
  end
end
