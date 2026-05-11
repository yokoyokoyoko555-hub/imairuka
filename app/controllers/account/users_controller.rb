module Account
  class UsersController < ApplicationController
    before_action -> { require_role!(:platform_admin, :owner, :admin) }

    def index
      @users = current_company.users.order(:email)
      @pending_invitations = current_company.user_invitations.pending.recent
    end
  end
end
