module Admin
  class CompaniesController < ApplicationController
    include InvitationLinks

    layout "admin"

    before_action -> { require_role!(:platform_admin) }

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
      @company = Company.find(params[:id])
      @users = User.where(company: @company).order(:email)
      @pending_invitations = @company.user_invitations.pending.recent
      @can_invite_user = @company.can_invite_user?
      @orders_count = Order.unscoped.where(company: @company).count
      @payments_count = PaymentRecord.unscoped.where(company: @company).count
    end

    def approve
      @company = Company.find(params[:id])
      @company.contract_status = "trialing"
      @company.trial_ends_at ||= 14.days.from_now

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

    private

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
