class InvitationAcceptancesController < ApplicationController
  skip_before_action :require_login
  skip_before_action :set_current_context
  skip_before_action :set_company_info

  layout "auth"

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

    if @user.save
      @invitation.update!(accepted_at: Time.current)
      session[:user_id] = @user.id
      redirect_to root_path, notice: "アカウントを作成しました。"
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
    return if @invitation&.available?

    redirect_to login_path, alert: "招待リンクが無効、または期限切れです。"
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
