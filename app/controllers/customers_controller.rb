class CustomersController < ApplicationController
  before_action :set_customer, only: [:show, :edit, :update, :destroy]

  def index
    @customers = Customer.all

    # 検索条件の適用
    if params[:company_name].present?
      @customers = @customers.where('company_name LIKE ?', "%#{params[:company_name]}%")
    end

    if params[:industry].present?
      @customers = @customers.where(industry: params[:industry])
    end

    if params[:status].present?
      @customers = @customers.where(status: params[:status])
    end

    # ソート機能
    case params[:sort]
    when 'company_name_asc'
      @customers = @customers.order(:company_name)
    when 'company_name_desc'
      @customers = @customers.order(company_name: :desc)
    when 'last_transaction_desc'
      @customers = @customers.joins(:orders).group(:id).order('MAX(orders.order_date) DESC')
    else
      @customers = @customers.order(:created_at)
    end

    @customers = @customers.page(params[:page]).per(20)
  end

  def show
    @customer = Customer.includes(:orders).find(params[:id])
  end

  def new
    @customer = Customer.new(status: nil)
  end

  def edit
  end

  def create
    # 一時保存の場合
    if params[:save_draft].present?
      begin
        # 新しい一時保存データを作成
        @customer = Customer.new(customer_params)
        @customer.draft = true
        
        # 一時保存時は重複チェックのみ実行
        if @customer.code.present?
          # 顧客コードが入力されている場合のみ重複チェック
          existing_customer = Customer.where(code: @customer.code).where.not(id: @customer.id).first
          if existing_customer
            @customer.errors.add(:code, 'この顧客コードは既に使用されています')
            render :new, status: :unprocessable_entity
            return
          end
        end
        
        @customer.save!(validate: false)
        redirect_to customers_path, notice: '一時保存しました'
        return
      rescue => e
        redirect_to customers_path, alert: "一時保存に失敗しました: #{e.message}"
        return
      end
    end
    
    # 通常の登録処理
    @customer = Customer.new(customer_params)
    @customer.draft = false  # 本保存として設定

    if @customer.save
      redirect_to @customer, notice: '顧客を登録しました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # 一時保存の場合
    if params[:save_draft].present?
      begin
        # 既存のレコードを一時保存として更新
        @customer.assign_attributes(customer_params)
        @customer.draft = true
        
        # 一時保存時は重複チェックのみ実行
        if @customer.code.present?
          # 顧客コードが入力されている場合のみ重複チェック
          existing_customer = Customer.where(code: @customer.code).where.not(id: @customer.id).first
          if existing_customer
            @customer.errors.add(:code, 'この顧客コードは既に使用されています')
            render :edit, status: :unprocessable_entity
            return
          end
        end
        
        @customer.save!(validate: false)
        redirect_to customers_path, notice: '一時保存しました'
        return
      rescue => e
        redirect_to customers_path, alert: "一時保存に失敗しました: #{e.message}"
        return
      end
    end
    
    # 通常の更新処理
    @customer.assign_attributes(customer_params)
    @customer.draft = false  # 一時保存を解除
    
    if @customer.save
      redirect_to @customer, notice: '顧客情報を更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # 論理削除されていない案件が存在するかチェック
    if @customer.orders.kept.exists?
      redirect_to customers_path, alert: '案件が紐づいているため削除できません。先に案件を削除してください。'
      return
    end
    
    if @customer.discard
      redirect_to customers_url, notice: '顧客を削除しました'
    else
      redirect_to customers_path, alert: @customer.errors.full_messages.join(', ')
    end
  end

  def bulk_delete
    customer_ids = params[:item_ids] || []
    deleted_count = 0
    error_count = 0

    customer_ids.each do |customer_id|
      customer = Customer.find(customer_id)
      
      # 論理削除されていない案件が存在するかチェック
      if customer.orders.kept.exists?
        error_count += 1
        next
      end
      
      if customer.discard
        deleted_count += 1
      else
        error_count += 1
      end
    end

    if error_count > 0
      redirect_to customers_path, alert: "#{deleted_count}件削除しました。#{error_count}件は案件が紐づいているため削除できませんでした。"
    else
      redirect_to customers_path, notice: "#{deleted_count}件の顧客を削除しました"
    end
  end

  private

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(
      :name, :code, :company_name, :industry, :established_date, :capital,
      :representative_name, :employee_count, :business_description, :status,
      :address, :phone, :email, :payment_term, :payment_method, :invoice_email,
      :notes, :is_active
    )
  end
end 