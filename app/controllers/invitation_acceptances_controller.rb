class InvitationAcceptancesController < ApplicationController
  skip_before_action :require_login
  skip_before_action :ensure_current_company_available
  skip_before_action :set_current_context
  skip_before_action :set_company_info

  layout "signup"

  before_action :set_invitation
  before_action :ensure_available_invitation

  def show
    @user = @invitation.company.users.build(
      email: @invitation.email,
      name: @invitation.name,
      role: @invitation.role
    )
  end

  def accept
    @user = @invitation.company.users.build(user_params.merge(
      email: @invitation.email,
      name: @invitation.name,
      role: @invitation.role,
      active: true
    ))

    unless UserMailer.otp_delivery_available?
      redirect_to login_path, alert: "認証メールの送信設定が未設定です。管理者にお問い合わせください。"
      return
    end

    if @user.save
      @invitation.update!(accepted_at: Time.current)
      otp_code = @user.generate_login_otp!
      begin
        UserMailer.login_otp(@user, otp_code).deliver_now
        session[:otp_user_id] = @user.id
        redirect_to login_otp_path, notice: "アカウントを作成しました。登録メールアドレスへ認証コードを送信しました。"
      rescue => e
        Rails.logger.error("Invitation OTP delivery failed: #{e.class}: #{e.message}")
        @user.clear_login_otp!
        redirect_to login_path, alert: "アカウントは作成されましたが、認証メールの送信に失敗しました。時間をおいてログインをお試しください。"
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_invitation
    @token = params[:token].to_s
    @invitation = UserInvitation.find_by_token(@token)
  end

  def ensure_available_invitation
    return if @invitation&.available? && @invitation.company.service_available?

    redirect_to login_path, alert: "招待リンクが無効、期限切れ、または契約状態により利用できません。"
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
