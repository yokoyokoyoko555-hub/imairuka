module Account
  class UserInvitationsController < ApplicationController
    include InvitationLinks

    before_action -> { require_role!(:platform_admin, :owner, :admin) }

    def new
      @invitation = current_company.user_invitations.build(role: "member")
    end

    def create
      @invitation = current_company.user_invitations.build(invitation_params.merge(invited_by: current_user))

      if @invitation.save
        store_invitation_link(@invitation)
        redirect_to account_users_path, notice: "招待を作成しました。URLを相手に共有してください。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def invitation_params
      params.require(:user_invitation).permit(:email, :name, :role)
    end
  end
end
