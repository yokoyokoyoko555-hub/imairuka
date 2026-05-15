module Admin
  class CompaniesController < ApplicationController
    include InvitationLinks

    layout "admin"

    before_action -> { require_role!(:platform_admin) }
    before_action :set_company, only: [
      :show,
      :approve,
      :activate_contract,
      :suspend_contract,
      :resume_contract,
      :cancel_contract
    ]

    def index
      @companies = Company.order(created_at: :desc)
    end

    def new
      @company = Company.new(
        contract_status: "trialing",
        plan_name: Company::DEFAULT_PLAN_NAME,
        trial_ends_at: 14.days.from_now
      )
      @owner = User.new(role: "owner", active: true)
    end

    def create
      @company = Company.new(company_params.merge(plan_name: Company::DEFAULT_PLAN_NAME))
      @owner = @company.users.build(owner_params.merge(role: "owner", active: true))

      if @company.save
        redirect_to admin_company_path(@company), notice: "新しい契約を追加しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      load_company_detail
    end

    def approve
      @company.assign_attributes(
        contract_status: "trialing",
        trial_ends_at: @company.trial_ends_at || 14.days.from_now,
        suspended_at: nil
      )

      if @company.save
        invitation = @company.user_invitations.pending.find_or_initialize_by(email: @company.email)
        invitation.assign_attributes(
          name: @company.representative,
          role: "owner",
          invited_by: current_user,
          skip_company_invite_limit: true
        )
        invitation.save!
        invitation.reset_token! if invitation.raw_token.blank?
        store_invitation_link(invitation)
        redirect_to admin_company_path(@company), notice: "契約を承認しました。初期管理者の招待URLを発行しました。"
      else
        redirect_to admin_company_path(@company), alert: @company.errors.full_messages.to_sentence
      end
    end

    def activate_contract
      change_contract_status!("active", "契約を利用中に変更しました。")
    end

    def suspend_contract
      @company.suspended_at = Time.current
      change_contract_status!("suspended", "契約を停止しました。利用者はログインできなくなります。")
    end

    def resume_contract
      @company.suspended_at = nil
      change_contract_status!("active", "契約を再開しました。")
    end

    def cancel_contract
      @company.suspended_at = Time.current
      change_contract_status!("canceled", "契約を解約に変更しました。利用者はログインできなくなります。")
    end

    private

    def set_company
      @company = Company.find(params[:id])
    end

    def load_company_detail
      @users = User.where(company: @company).order(:email)
      @pending_invitations = @company.user_invitations.pending.recent
      @can_invite_user = @company.can_invite_user?
      @orders_count = Order.unscoped.where(company: @company).count
      @payments_count = PaymentRecord.unscoped.where(company: @company).count
    end

    def change_contract_status!(status, message)
      @company.contract_status = status

      if @company.save
        redirect_to admin_company_path(@company), notice: message
      else
        redirect_to admin_company_path(@company), alert: @company.errors.full_messages.to_sentence
      end
    end

    def company_params
      params.require(:company).permit(
        :name,
        :tenant_slug,
        :invoice_number,
        :postal_code,
        :address,
        :phone,
        :email,
        :representative,
        :business_type,
        :contract_status,
        :trial_ends_at
      )
    end

    def owner_params
      params.require(:owner).permit(:name, :email, :password, :password_confirmation)
    end
  end
end
