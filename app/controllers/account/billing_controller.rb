module Account
  class BillingController < ApplicationController
    before_action -> { require_role!(:platform_admin, :owner, :admin) }

    def add_user_slot
      redirect_to account_users_path, alert: "追加アカウントはStripe課金ではなく、運営側で契約変更後に利用できます。"
    end
  end
end
