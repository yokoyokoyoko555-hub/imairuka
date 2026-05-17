module Admin
  class CompaniesController < ApplicationController
    include InvitationLinks

    layout "admin"

    before_action -> { require_role!(:platform_admin) }
    before_action :set_company, only: [
      :show,
      :edit,
      :update,
      :approve,
      :mark_paid,
      :activate_contract,
      :suspend_contract,
      :resume_contract,
      :cancel_contract
    ]

    def index
      @companies = Company.includes(:vendor).order(created_at: :desc)
    end

    def new
      @company = Company.new(
        contract_status: "pending_review",
        plan_name: Company::DEFAULT_PLAN_NAME,
        sales_channel: "direct",
        billing_status: "unbilled",
        contract_amount: Company::DEFAULT_CONTRACT_AMOUNT,
        contract_months: Company::DEFAULT_CONTRACT_MONTHS
      )
      @owner = User.new(role: "owner", active: true)
      load_vendors
    end

    def create
      @company = Company.new(company_params.merge(plan_name: Company::DEFAULT_PLAN_NAME))
      @owner = @company.users.build(owner_params.merge(role: "owner", active: true))

      if @company.save
        redirect_to admin_company_path(@company), notice: "新しい契約候補を追加しました。"
      else
        load_vendors
        render :new, status: :unprocessable_entity
      end
    end

    def show
      load_company_detail
    end

    def edit
      load_vendors
    end

    def update
      if @company.update(company_params.merge(plan_name: Company::DEFAULT_PLAN_NAME))
        redirect_to admin_company_path(@company), notice: "契約情報を更新しました。"
      else
        load_vendors
        render :edit, status: :unprocessable_entity
      end
    end

    def approve
      @company.assign_attributes(
        contract_status: "past_due",
        billing_status: "invoiced",
        invoiced_on: Date.current,
        payment_due_on: @company.payment_due_on || 1.month.from_now.to_date,
        internal_invoice_number: @company.internal_invoice_number.presence || next_invoice_number
      )

      if @company.save
        redirect_to admin_company_path(@company), notice: "請求書発行済みにしました。銀行振込の入金確認後に利用開始できます。"
      else
        redirect_to admin_company_path(@company), alert: @company.errors.full_messages.to_sentence
      end
    end

    def mark_paid
      @company.assign_attributes(
        contract_status: "active",
        billing_status: "paid",
        paid_on: Date.current,
        contract_starts_on: @company.contract_starts_on || Date.current,
        contract_ends_on: @company.contract_ends_on || Date.current.advance(months: @company.contract_months),
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
        redirect_to admin_company_path(@company), notice: "入金済みにして利用開始しました。初期管理者の招待URLを発行しました。"
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

    def load_vendors
      @vendors = Vendor.active.order(:name)
    end

    def next_invoice_number
      "IM-#{Time.current.strftime('%Y%m%d')}-#{@company.id || SecureRandom.hex(3)}"
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
        :sales_channel,
        :vendor_id,
        :billing_status,
        :internal_invoice_number,
        :invoiced_on,
        :payment_due_on,
        :paid_on,
        :contract_amount,
        :contract_months,
        :contract_starts_on,
        :contract_ends_on,
        :contract_notes,
        :additional_user_slots,
        :trial_ends_at
      )
    end

    def owner_params
      params.require(:owner).permit(:name, :email, :password, :password_confirmation)
    end
  end
end
