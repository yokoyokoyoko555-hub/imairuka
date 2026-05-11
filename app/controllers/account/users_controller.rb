module Account
  class UsersController < ApplicationController
    before_action -> { require_role!(:platform_admin, :owner, :admin) }
    before_action :set_user, only: [:update, :activate, :suspend]

    def index
      load_index
    end

    def update
      unless UserInvitation::INVITABLE_ROLES.include?(user_params[:role])
        redirect_to account_users_path, alert: "選択できない権限です。"
        return
      end

      if changing_self_role?
        redirect_to account_users_path, alert: "自分自身の権限は変更できません。"
        return
      end

      if @user.update(user_params)
        redirect_to account_users_path, notice: "ユーザー情報を更新しました。"
      else
        load_index
        render :index, status: :unprocessable_entity
      end
    end

    def activate
      @user.update!(active: true)
      redirect_to account_users_path, notice: "ユーザーを有効にしました。"
    end

    def suspend
      if @user == current_user
        redirect_to account_users_path, alert: "自分自身は停止できません。"
        return
      end

      @user.update!(active: false)
      redirect_to account_users_path, notice: "ユーザーを停止しました。"
    end

    private

    def set_user
      @user = current_company.users.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:name, :role)
    end

    def changing_self_role?
      @user == current_user && user_params[:role].present? && user_params[:role] != current_user.role
    end

    def load_index
      @users = current_company.users.order(:email)
      @pending_invitations = current_company.user_invitations.pending.recent
      @can_invite_user = current_company.can_invite_user?
    end
  end
end
