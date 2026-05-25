class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create, :otp, :verify_otp, :destroy]
  skip_before_action :ensure_current_company_available, only: [:new, :create, :otp, :verify_otp, :destroy]
  skip_before_action :prevent_read_only_write, only: [:new, :create, :otp, :verify_otp, :destroy]

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

      if issue_otp_for(user)
        redirect_to login_otp_path, notice: "登録メールアドレスへ認証コードを送信しました。"
      else
        flash.now[:alert] = "認証メールの送信に失敗しました。時間をおいて再度お試しください。"
        render :new, status: :service_unavailable
      end
    else
      flash.now[:alert] = "メールアドレスまたはパスワードが正しくありません。"
      render :new, status: :unprocessable_entity
    end
  end

  def otp
    redirect_to login_path, alert: "先にメールアドレスとパスワードを入力してください。" unless pending_otp_user
  end

  def verify_otp
    user = pending_otp_user
    unless user
      redirect_to login_path, alert: "認証コードの確認を最初からやり直してください。"
      return
    end

    if user.verify_login_otp(params[:otp_code])
      session.delete(:otp_user_id)
      session[:user_id] = user.id
      user.update!(last_login_at: Time.current)
      redirect_to root_path, notice: "ログインしました。"
    else
      flash.now[:alert] = "認証コードが正しくないか、有効期限が切れています。"
      render :otp, status: :unprocessable_entity
    end
  end

  def destroy
    reset_login_state
    session.delete(:otp_user_id)
    redirect_to login_path, notice: "ログアウトしました。"
  end

  private

  def issue_otp_for(user)
    return false unless UserMailer.otp_delivery_available?

    otp_code = user.generate_login_otp!
    session[:otp_user_id] = user.id
    UserMailer.login_otp(user, otp_code).deliver_now
    true
  rescue => e
    Rails.logger.error("Login OTP delivery failed: #{e.class}: #{e.message}")
    user.clear_login_otp! if user.persisted?
    session.delete(:otp_user_id)
    false
  end

  def pending_otp_user
    @pending_otp_user ||= User.active.includes(:company).find_by(id: session[:otp_user_id])
  end
end
