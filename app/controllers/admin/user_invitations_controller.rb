module Admin
  class UserInvitationsController < ApplicationController
    include InvitationLinks

    layout "admin"

    before_action -> { require_role!(:platform_admin) }
    before_action :set_company
    before_action :ensure_invitable!, only: [:new, :create]
    before_action :set_invitation, only: [:destroy, :reissue]

    def new
      @invitation = @company.user_invitations.build(role: "member")
    end

    def create
      @invitation = @company.user_invitations.build(invitation_params.merge(invited_by: current_user))

      if @invitation.save
        store_invitation_link(@invitation)
        redirect_to admin_company_path(@company), notice: "招待を作成しました。URLを相手に共有してください。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      @invitation.destroy!
      redirect_to admin_company_path(@company), notice: "招待を取り消しました。"
    end

    def reissue
      @invitation.reset_token!
      store_invitation_link(@invitation)
      redirect_to admin_company_path(@company), notice: "招待URLを再発行しました。"
    end

    private

    def set_company
      @company = Company.find(params[:company_id])
    end

    def set_invitation
      @invitation = @company.user_invitations.pending.find(params[:id])
    end

    def ensure_invitable!
      return if @company.can_invite_user?

      redirect_to admin_company_path(@company), alert: @company.user_limit_message
    end

    def invitation_params
      params.require(:user_invitation).permit(:email, :name, :role)
    end
  end
end
