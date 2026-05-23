class OrdersController < ApplicationController
  require 'stripe'
  before_action :set_order, only: [:show, :edit, :destroy, :generate_project_plan]
  before_action :set_customers_and_statuses, only: %i[ new edit create update ]

  # クラス変数として案件データを保持
  @@orders = []

  def index
    @orders = Order.includes(:customer, :order_status)
                  .order(created_at: :desc)

    if params[:customer_name].present?
      @orders = @orders.joins(:customer).where('customers.name LIKE ?', "%#{params[:customer_name]}%")
    end

    if params[:status].present?
      @orders = @orders.joins(:order_status).where(order_statuses: { code: params[:status] })
    end

    if params[:date_from].present?
      @orders = @orders.where('order_date >= ?', params[:date_from])
    end

    if params[:date_to].present?
      @orders = @orders.where('order_date <= ?', params[:date_to])
    end

    @total_count = @orders.count
    @orders = @orders.page(params[:page]).per(20)
  end

  def show
    @order = Order.with_discarded.includes(:customer).find(params[:id])
  end

  def new
    @order = Order.new(
      order_date: Date.current
    )
    # 案件番号を事前に設定
    @order.order_number = generate_order_number if @order.order_number.blank?
    @order.order_items.build
  end

  def edit
    # 一時保存データも含めて検索
    @order = Order.with_discarded.includes(:customer, :order_items).find(params[:id])
    set_customers_and_statuses
  end

  def create
    # 一時保存の場合
    if params[:save_draft].present?
      begin
        # 新しい一時保存データを作成
        @draft = Order.new(order_params)
        @draft.draft = true
        
        # 案件番号が設定されていない場合は設定
        if @draft.order_number.blank?
          @draft.order_number = generate_order_number
        end
        
        # 商品が未選択または数量が空の場合は削除、単価が未設定の場合は設定
        if @draft.order_items.any?
          @draft.order_items.each do |item|
            if item.product_id.blank? || item.quantity.blank?
              item.mark_for_destruction
            elsif item.product_id.present? && item.unit_price.blank?
              # 商品が選択されているが単価が未設定の場合は商品から取得
              product = Product.find(item.product_id)
              item.unit_price = product.unit_price || 0
              # 数量が未設定の場合は1を設定
              item.quantity = 1 if item.quantity.blank?
              item.amount = (item.unit_price || 0) * (item.quantity || 1)
            end
          end
        end
        
        @draft.save!(validate: false)
        redirect_to orders_path, notice: '一時保存しました'
        return
      rescue => e
        # データベース制約エラーの場合は日本語メッセージを表示
        if e.is_a?(ActiveRecord::RecordNotUnique) || e.message.include?('duplicate key value')
          redirect_to orders_path, alert: '案件番号が重複しています。別の案件番号を入力してください。'
        else
          redirect_to orders_path, alert: "一時保存に失敗しました: #{e.message}"
        end
        return
      end
    end
    
    # 通常の登録処理
    @order = Order.new(order_params)
    @order.draft = false  # 本保存として設定
    
    # 商品の単価と金額を設定
    if @order.order_items.any?
      @order.order_items.each do |item|
        if item.product_id.present? && item.unit_price.blank?
          product = Product.find(item.product_id)
          item.unit_price = product.unit_price || 0
          item.amount = item.unit_price * (item.quantity || 1)
        end
      end
    end
    
    if @order.save
      redirect_to @order, notice: '案件を登録しました'
    else
      # エラー時に案件番号をクリア
      @order.order_number = nil
      set_customers_and_statuses
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # 既存のレコードを取得
    @order = Order.with_discarded.includes(:customer, :order_items).find(params[:id])
    
    # 一時保存の場合
    if params[:save_draft].present?
      begin
        # 既存のレコードを一時保存として更新
        @order.assign_attributes(update_params)
        @order.draft = true
        
        # 案件番号が設定されていない場合は設定
        if @order.order_number.blank?
          @order.order_number = generate_order_number
        end
        
        # 商品が未選択または数量が空の場合は削除、単価が未設定の場合は設定
        if @order.order_items.any?
          @order.order_items.each do |item|
            if item.product_id.blank? || item.quantity.blank?
              item.mark_for_destruction
            elsif item.product_id.present? && item.unit_price.blank?
              # 商品が選択されているが単価が未設定の場合は商品から取得
              product = Product.find(item.product_id)
              item.unit_price = product.unit_price || 0
              # 数量が未設定の場合は1を設定
              item.quantity = 1 if item.quantity.blank?
              item.amount = (item.unit_price || 0) * (item.quantity || 1)
            end
          end
        end
        
        @order.save!(validate: false)
        redirect_to orders_path, notice: '一時保存しました'
        return
      rescue => e
        # データベース制約エラーの場合は日本語メッセージを表示
        if e.is_a?(ActiveRecord::RecordNotUnique) || e.message.include?('duplicate key value')
          redirect_to orders_path, alert: '案件番号が重複しています。別の案件番号を入力してください。'
        else
          redirect_to orders_path, alert: "一時保存に失敗しました: #{e.message}"
        end
        return
      end
    end
    
    # 通常の更新処理
    @order.assign_attributes(update_params)
    @order.draft = false  # 一時保存を解除
    
    # 商品の単価と金額を設定
    if @order.order_items.any?
      @order.order_items.each do |item|
        if item.product_id.present? && item.unit_price.blank?
          product = Product.find(item.product_id)
          item.unit_price = product.unit_price || 0
          item.amount = (item.unit_price || 0) * (item.quantity || 1)
        end
      end
    end
    
    # 注文商品のバリデーション（一時保存時はスキップ）
    order_items_params = update_params[:order_items_attributes]
    if order_items_params.blank? || 
       order_items_params.values.all? { |attrs| attrs['_destroy'] == '1' }
      @order.errors.add(:order_items, '商品を選択してください')
      set_customers_and_statuses
      render :edit, status: :unprocessable_entity
      return
    end

    # 更新を実行
    if @order.save
      redirect_to @order, notice: '案件を更新しました'
    else
      # バリデーションエラー時は入力値を保持（@orderは既にassign_attributesされている）
      set_customers_and_statuses
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @order.discard
    redirect_to orders_path, notice: '案件を削除しました'
  end

  def generate_project_plan
    OrderProjectPlanGenerator.new(@order).generate.each do |attrs|
      @order.project_tasks.create!(attrs.merge(company: current_company))
    end
    redirect_to project_management_path(@order, anchor: "project-management"), notice: "ガントチャート下書きを作成しました"
  rescue => e
    Rails.logger.error("Project plan generation failed: #{e.class} #{e.message}")
    redirect_to project_management_path(@order, anchor: "project-management"), alert: "ガントチャート下書きの作成に失敗しました"
  end

  def export
    # 案件データのエクスポート
  end

  def import
    # 案件データのインポート
  end

  def billing
    # 全ての案件を取得
    @orders = Order.includes(:customer, :order_status)
                  .order(created_at: :desc)
                  .page(params[:page])
                  .per(20)  # 1件ずつ表示

    # 検索条件の適用
    if params[:order_number].present?
      @orders = @orders.where('order_number LIKE ?', "%#{params[:order_number]}%")
    end

    if params[:customer_name].present?
      @orders = @orders.joins(:customer).where('customers.name LIKE ?', "%#{params[:customer_name]}%")
    end

    if params[:status].present?
      @orders = @orders.joins(:order_status).where(order_statuses: { code: params[:status] })
    end

    if params[:payment_due_date_from].present?
      @orders = @orders.where('payment_due_date >= ?', params[:payment_due_date_from])
    end

    if params[:payment_due_date_to].present?
      @orders = @orders.where('payment_due_date <= ?', params[:payment_due_date_to])
    end
  end

  def show_billing
    @order = Order.includes(:customer, :order_items, :order_status, :histories).find(params[:id])
  end

  def edit_payment
    @order = Order.includes(:customer, :order_items, :order_status).find(params[:id])
  end

  def update_payment
    @order = Order.find(params[:id])
    if @order.update(payment_params)
      @order.histories.create!(
        action: :payment_status_changed,
        description: "入金情報を更新しました",
        staff_name: current_user&.name || 'システム'
      )
    end
    redirect_to billing_orders_path, notice: '入金情報を更新しました。'
  end

  def print
    @order = @@orders.find { |o| o[:id] == params[:id].to_i }
    render layout: 'print'
  end

  def preview
    @order = @@orders.find { |o| o[:id] == params[:id].to_i }
    render layout: 'print'
  end

  def edit_delivery
    @order = @@orders.find { |o| o[:id] == params[:id].to_i }
  end

  def edit_billing
    @order = @@orders.find { |o| o[:id] == params[:id].to_i }
  end

  def preview_delivery
    @order = @@orders.find { |o| o[:id] == params[:id].to_i }
    render layout: 'print'
  end

  def preview_billing
    @order = @@orders.find { |o| o[:id] == params[:id].to_i }
    render layout: 'print'
  end

  def preview_receipt
    @order = @@orders.find { |o| o[:id] == params[:id].to_i }
    render layout: 'print'
  end

  def print_delivery
    @order = @@orders.find { |o| o[:id] == params[:id].to_i }
    render layout: 'print'
  end

  def print_receipt
    @order = @@orders.find { |o| o[:id] == params[:id].to_i }
    render layout: 'print'
  end

  def print_order
    @order = @@orders.find { |o| o[:id] == params[:id].to_i }
    render layout: 'print'
  end

  def print_invoice
    @order = @@orders.find { |o| o[:id] == params[:id].to_i }
    render layout: 'print'
  end

  def print_tax_invoice
    @order = @@orders.find { |o| o[:id] == params[:id].to_i }
    render layout: 'print'
  end

  def preview_order
    @order = @@orders.find { |o| o[:id] == params[:id].to_i }
    render layout: 'print'
  end

  def purchase
    # 基本の発注一覧を取得
    @purchases = Array(@@orders).select { |order| ['ordered', 'received', 'paid'].include?(order[:status]) }

    # 検索条件の適用
    if params[:search_order_number].present?
      @purchases = @purchases.select { |order| order[:order_number].include?(params[:search_order_number]) }
    end

    if params[:search_supplier_name].present?
      @purchases = @purchases.select { |order| order[:supplier_name]&.include?(params[:search_supplier_name]) }
    end

    if params[:search_status].present?
      @purchases = @purchases.select { |order| order[:status] == params[:search_status] }
    end

    if params[:search_delivery_date_from].present?
      from_date = Date.parse(params[:search_delivery_date_from])
      @purchases = @purchases.select { |order| order[:delivery_date] && order[:delivery_date].to_date >= from_date }
    end

    if params[:search_delivery_date_to].present?
      to_date = Date.parse(params[:search_delivery_date_to])
      @purchases = @purchases.select { |order| order[:delivery_date] && order[:delivery_date].to_date <= to_date }
    end

    # 作成日時の降順でソート
    @purchases = @purchases.sort_by { |order| order[:order_date] }.reverse

    # @purchasesがnilの場合のフォールバック
    @purchases ||= []
  end

  def edit_purchase
    @purchase = @@orders.find { |o| o[:id] == params[:id].to_i }
  end

  def update_purchase
    @purchase = @@orders.find { |o| o[:id] == params[:id].to_i }
    if @purchase
      @purchase[:supplier_id] = params[:purchase][:supplier_id]
      @purchase[:delivery_date] = params[:purchase][:delivery_date]
      @purchase[:delivery_address] = params[:purchase][:delivery_address]
      @purchase[:notes] = params[:purchase][:notes]
      @purchase[:status] = 'ordered'
      @purchase[:history] << {
        action: '発注完了',
        date: Time.current,
        user: current_user&.name || 'システム'
      }
    end
    redirect_to purchase_orders_path, notice: '発注情報を更新しました。'
  end

  def receiving
    # 基本の入荷一覧を取得（発注済みの案件のみ）
    @purchases = Array(@@orders).select { |order| order[:status] == 'ordered' }

    # 検索条件の適用
    if params[:search_order_number].present?
      @purchases = @purchases.select { |order| order[:order_number].include?(params[:search_order_number]) }
    end

    if params[:search_supplier_name].present?
      @purchases = @purchases.select { |order| order[:supplier_name]&.include?(params[:search_supplier_name]) }
    end

    if params[:search_status].present?
      @purchases = @purchases.select { |order| order[:status] == params[:search_status] }
    end

    if params[:search_delivery_date_from].present?
      from_date = Date.parse(params[:search_delivery_date_from])
      @purchases = @purchases.select { |order| order[:delivery_date] && order[:delivery_date].to_date >= from_date }
    end

    if params[:search_delivery_date_to].present?
      to_date = Date.parse(params[:search_delivery_date_to])
      @purchases = @purchases.select { |order| order[:delivery_date] && order[:delivery_date].to_date <= to_date }
    end

    # 作成日時の降順でソート
    @purchases = @purchases.sort_by { |order| order[:order_date] }.reverse

    # @purchasesがnilの場合のフォールバック
    @purchases ||= []
  end

  def edit_receiving
    @purchase = @@orders.find { |o| o[:id] == params[:id].to_i }
  end

  def update_receiving
    @purchase = @@orders.find { |o| o[:id] == params[:id].to_i }
    if @purchase
      @purchase[:receiving_date] = params[:purchase][:receiving_date]
      @purchase[:receiving_staff] = params[:purchase][:receiving_staff]
      @purchase[:receiving_notes] = params[:purchase][:receiving_notes]
      @purchase[:status] = 'received'
      @purchase[:history] << {
        action: '入荷完了',
        date: Time.current,
        user: params[:purchase][:receiving_staff]
      }
    end
    redirect_to receiving_orders_path, notice: '入荷情報を更新しました。'
  end

  def payment_purchase
    # 基本の支払一覧を取得（入荷済みの案件のみ）
    @purchases = Array(@@orders).select { |order| order[:status] == 'received' }

    # 検索条件の適用
    if params[:search_order_number].present?
      @purchases = @purchases.select { |order| order[:order_number].include?(params[:search_order_number]) }
    end

    if params[:search_supplier_name].present?
      @purchases = @purchases.select { |order| order[:supplier_name]&.include?(params[:search_supplier_name]) }
    end

    if params[:search_status].present?
      @purchases = @purchases.select { |order| order[:status] == params[:search_status] }
    end

    if params[:search_payment_due_date_from].present?
      from_date = Date.parse(params[:search_payment_due_date_from])
      @purchases = @purchases.select { |order| order[:payment_due_date] && order[:payment_due_date].to_date >= from_date }
    end

    if params[:search_payment_due_date_to].present?
      to_date = Date.parse(params[:search_payment_due_date_to])
      @purchases = @purchases.select { |order| order[:payment_due_date] && order[:payment_due_date].to_date <= to_date }
    end

    # 作成日時の降順でソート
    @purchases = @purchases.sort_by { |order| order[:order_date] }.reverse

    # @purchasesがnilの場合のフォールバック
    @purchases ||= []
  end

  def edit_payment_purchase
    @purchase = @@orders.find { |o| o[:id] == params[:id].to_i }
  end

  def update_payment_purchase
    @purchase = @@orders.find { |o| o[:id] == params[:id].to_i }
    if @purchase
      @purchase[:payment_date] = params[:purchase][:payment_date]
      @purchase[:payment_method] = params[:purchase][:payment_method]
      @purchase[:payment_notes] = params[:purchase][:payment_notes]
      @purchase[:status] = 'paid'
      @purchase[:history] << {
        action: '支払完了',
        date: Time.current,
        user: current_user&.name || 'システム'
      }
    end
    redirect_to payment_purchase_orders_path, notice: '支払情報を更新しました。'
  end

  def show_purchase
    @purchase = {
      id: params[:id].to_i,
      order_number: "PUR-#{Time.current.strftime('%Y%m%d')}-#{format('%03d', params[:id].to_i)}",
      order_date: Time.current - 5.days,
      supplier_id: 1,
      supplier_name: "株式会社サンプル仕入先",
      delivery_date: Time.current + 5.days,
      delivery_address: "東京都千代田区サンプル1-1-1",
      notes: "初回発注のため、初期設定サポートが必要です。",
      items: [
        {
          product_code: "PRD-001",
          product_name: "クラウドサーバー",
          unit_price: 50000,
          quantity: 3,
          amount: 150000
        },
        {
          product_code: "PRD-002",
          product_name: "セキュリティソフト",
          unit_price: 30000,
          quantity: 2,
          amount: 60000
        }
      ],
      total_amount: 210000,
      status: "ordered",
      history: [
        {
          action: "発注登録",
          date: Time.current - 5.days,
          user: "山田太郎"
        },
        {
          action: "発注完了",
          date: Time.current - 4.days,
          user: "山田太郎"
        }
      ]
    }
  end

  def show_payment_purchase
    @purchase = {
      id: params[:id].to_i,
      order_number: "PUR-#{Time.current.strftime('%Y%m%d')}-#{format('%03d', params[:id].to_i)}",
      order_date: Time.current - 10.days,
      supplier_id: 2,
      supplier_name: "株式会社テスト仕入先",
      delivery_date: Time.current - 2.days,
      delivery_address: "東京都港区テスト2-2-2",
      notes: "支払期限は納品後30日以内です。",
      items: [
        {
          product_code: "PRD-003",
          product_name: "ネットワーク機器",
          unit_price: 100000,
          quantity: 1,
          amount: 100000
        }
      ],
      total_amount: 100000,
      status: "received",
      payment_due_date: Time.current + 28.days,
      payment_method: "銀行振込",
      payment_notes: "支払予定",
      history: [
        {
          action: "発注登録",
          date: Time.current - 10.days,
          user: "鈴木一郎"
        },
        {
          action: "発注完了",
          date: Time.current - 9.days,
          user: "鈴木一郎"
        },
        {
          action: "入荷完了",
          date: Time.current - 2.days,
          user: "田中次郎"
        }
      ]
    }
  end

  def show_delivery
    @order = {
      id: params[:id].to_i,
      order_number: "ORD-#{Time.current.strftime('%Y%m%d')}-#{format('%03d', params[:id].to_i)}",
      order_date: Time.current - 7.days,
      customer_name: "株式会社サンプル",
      total_amount: 180000,
      status: "delivered",
      staff_name: "佐藤花子",
      items: [
        {
          product_code: "PRD-001",
          product_name: "クラウドサーバー（月額）",
          unit_price: 60000,
          quantity: 3,
          amount: 180000
        }
      ],
      notes: "既存顧客からの追加契約です。",
      delivery_date: Time.current - 1.day,
      delivery_address: "東京都千代田区サンプル1-1-1",
      delivery_staff: "田中次郎",
      history: [
        {
          action: "案件登録",
          date: Time.current - 7.days,
          user: "佐藤花子"
        },
        {
          action: "発注完了",
          date: Time.current - 6.days,
          user: "佐藤花子"
        },
        {
          action: "納品完了",
          date: Time.current - 1.day,
          user: "田中次郎"
        }
      ]
    }
  end

  def show_billing
    @order = Order.includes(:customer, :order_items, :order_status, :histories).find(params[:id])
  end

  def show_payment
    @order = {
      id: params[:id].to_i,
      order_number: "ORD-#{Time.current.strftime('%Y%m%d')}-#{format('%03d', params[:id].to_i)}",
      order_date: Time.current - 20.days,
      customer_name: "株式会社デモ",
      total_amount: 750000,
      status: "paid",
      staff_name: "渡辺直子",
      items: [
        {
          product_code: "PRD-005",
          product_name: "クラウドストレージ（年間）",
          unit_price: 250000,
          quantity: 3,
          amount: 750000
        }
      ],
      notes: "大量データの移行作業が必要です。",
      delivery_date: Time.current - 13.days,
      delivery_address: "東京都渋谷区デモ3-3-3",
      delivery_staff: "小林誠",
      billing_date: Time.current - 12.days,
      billing_address: "東京都渋谷区デモ3-3-3",
      payment_due_date: Time.current - 2.days,
      payment_date: Time.current - 1.day,
      payment_method: "クレジットカード",
      payment_notes: "カード決済完了",
      history: [
        {
          action: "案件登録",
          date: Time.current - 20.days,
          user: "渡辺直子"
        },
        {
          action: "発注完了",
          date: Time.current - 19.days,
          user: "渡辺直子"
        },
        {
          action: "納品完了",
          date: Time.current - 13.days,
          user: "小林誠"
        },
        {
          action: "請求完了",
          date: Time.current - 12.days,
          user: "システム"
        },
        {
          action: "入金完了",
          date: Time.current - 1.day,
          user: "システム"
        }
      ]
    }
  end

  def preview
    @order = {
      id: 'preview',
      order_number: "ORD-#{Time.current.strftime('%Y%m%d')}-001",
      order_date: Time.current,
      customer_name: '株式会社サンプル',
      staff_name: '山田太郎',
      status: 'received',
      total_amount: 150000,
      items: [
        { product_code: 'PRD-001', product_name: 'クラウドサーバー（月額）', unit_price: 50000, quantity: 3, amount: 150000 }
      ],
      notes: 'ご確認ください。',
      delivery_address: '東京都足立区西新井6-2-22',
      delivery_staff: '佐藤花子',
      billing_address: '東京都足立区西新井6-2-22',
      payment_due_date: Time.current + 30.days,
      payment_method: '銀行振込'
    }
    render layout: 'print'
  end

  def checkout
    @order = Order.find(params[:id])
    if @order.nil?
      redirect_to orders_path, alert: '指定された案件が見つかりませんでした。'
      return
    end

    company = current_company
    unless StripeSettings.configured?
      redirect_to show_billing_order_path(@order), alert: "Stripe secret key が未設定です。"
      return
    end

    unless StripeSettings.checkout_available?(company)
      redirect_to settings_path(tab: "stripe"), alert: "決済を開始するには Stripe 設定を完了してください。"
      return
    end

    begin
      existing_payment_link = @order.payment_records.pending
        .where.not(stripe_checkout_url: [nil, ""])
        .where("created_at > ?", 23.hours.ago)
        .order(created_at: :desc)
        .first

      if existing_payment_link
        redirect_to show_billing_order_path(@order), notice: "Existing payment link is still available."
        return
      end

      session = Stripe::Checkout::Session.create(
        payment_method_types: ['card'],
        line_items: [{
          price_data: {
            currency: 'jpy',
            product_data: {
              name: @order.customer.name,
              description: "案件番号: #{@order.order_number}"
            },
            unit_amount: @order.total_amount
          },
          quantity: 1
        }],
        mode: 'payment',
        success_url: "#{success_url}?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: cancel_url,
        payment_intent_data: stripe_payment_intent_data(company, @order),
        metadata: {
          order_id: @order.id,
          company_id: company.id
        }
      )

      @order.payment_records.find_or_create_by!(stripe_checkout_session_id: session.id) do |payment|
        payment.company = company
        payment.stripe_account_id = StripeSettings.connect_mode? ? company.stripe_account_id : nil
        payment.stripe_checkout_url = session.url
        payment.status = "pending"
        payment.amount = @order.total_amount
        payment.currency = "jpy"
        payment.payment_method_type = "card"
      end

      redirect_to show_billing_order_path(@order), notice: "顧客送付用の決済リンクを作成しました。"
    rescue => e
      Rails.logger.error("Stripe決済エラー: #{e.message}")
      redirect_to billing_orders_path, alert: '決済処理中にエラーが発生しました。管理者にお問い合わせください。'
    end
  end

  def cancel
    flash[:alert] = "決済がキャンセルされました。"
    redirect_to billing_orders_path
  end

  def success
    if params[:session_id].present? && StripeSettings.configured?
      session = Stripe::Checkout::Session.retrieve(params[:session_id])
      if session.payment_status == "paid" && session.metadata&.order_id.present?
        company = Company.find_by(id: session.metadata.company_id) || current_company
        order = company.orders.find_by(id: session.metadata.order_id)
        if order
          order.update(payment_date: Date.current)
          payment = order.payment_records.find_by(stripe_payment_intent_id: session.payment_intent) if session.payment_intent.present?
          payment ||= order.payment_records.find_or_initialize_by(stripe_checkout_session_id: session.id)
          payment.tap do |payment|
            payment.company ||= company
            payment.stripe_account_id ||= StripeSettings.connect_mode? ? payment.company&.stripe_account_id : nil
            payment.stripe_payment_intent_id = session.payment_intent
            payment.stripe_checkout_session_id ||= session.id
            payment.status = "paid"
            payment.amount = session.amount_total || order.total_amount
            payment.currency = session.currency || "jpy"
            payment.payment_method_type ||= "card"
            payment.paid_at ||= Time.current
            payment.save!
            order.payment_records.pending.where.not(id: payment.id).update_all(status: "canceled", updated_at: Time.current)
          end
        end
      end
    end
    flash[:notice] = "決済が完了しました。"
    redirect_to billing_orders_path
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe決済確認エラー: #{e.message}")
    flash[:notice] = "決済完了画面に戻りました。決済状態はStripe側で確認してください。"
    redirect_to billing_orders_path
  end

  def stripe_payment_intent_data(company, order)
    return {} if StripeSettings.direct_mode?

    {
      on_behalf_of: company.stripe_account_id,
      transfer_data: {
        destination: company.stripe_account_id
      },
      metadata: {
        order_id: order.id,
        company_id: company.id
      }
    }
  end

  def bulk_delete
    @orders = Order.where(id: params[:item_ids])
    
    if @orders.discard_all
      flash[:success] = "#{@orders.count}件の案件を削除しました。"
    else
      flash[:error] = "案件の削除に失敗しました。"
    end
    
    redirect_to orders_path, status: :see_other
  end

  private

  def prevent_duplicate_submission
    if session[:last_submitted_at] && session[:last_submitted_at] > 5.seconds.ago
      redirect_to @order, alert: '処理中です。しばらくお待ちください。'
      return
    end
    session[:last_submitted_at] = Time.current
  end

  def set_order
    @order = Order.with_discarded.includes(:customer, :order_items).find(params[:id])
  end

  def load_project_management
    @project_phase_tasks = @order.project_tasks.phases.includes(:assignee, :subtasks).ordered
    @project_detail_tasks = @order.project_tasks.details.includes(:assignee, :parent).ordered
    @project_tasks = @order.project_tasks.includes(:assignee, :parent).ordered
    @project_issues = @order.project_issues.includes(:assignee).ordered
    @assignments = @order.assignments.includes(:user).order(:role, :id)
    @company_users = current_company.users.active.order(:name, :email)
    @new_project_phase = @order.project_tasks.build(start_date: Date.current, due_date: Date.current + 7.days)
    @new_project_task = @order.project_tasks.build(start_date: Date.current, due_date: Date.current + 2.days)
    @new_project_issue = @order.project_issues.build
    @new_assignment = @order.assignments.build
  end

  def set_customers_and_statuses
    @customers = Customer.where("draft = ? AND is_active = ?", false, true).order(:company_name)
    @order_statuses = OrderStatus.where(is_active: true)
    @products = Product.where(draft: false, is_active: true).order(:name)
  end

  def generate_order_number
    prefix = "ORD-#{Date.current.strftime('%Y%m')}"
    last_order = Order.kept.where("order_number LIKE ?", "#{prefix}-%").order(order_number: :desc).first
    next_number = last_order&.order_number.to_s.split("-").last.to_i + 1

    # 重複しない番号を見つけるまでループ
    loop do
      candidate_number = "#{prefix}-#{format('%04d', next_number)}"
      unless Order.kept.exists?(order_number: candidate_number)
        return candidate_number
      end
      next_number += 1
    end
  end

  def order_params
    params.require(:order).permit(
      :customer_id,
      :staff_name,
      :order_status_id,
      :order_date,
      :payment_due_date,
      :payment_method,
      :project_name,
      :project_summary,
      :notes,
      :delivery_date,
      :delivery_address,
      order_items_attributes: [
        :id,
        :product_id,
        :unit_price,
        :quantity,
        :amount,
        :_destroy
      ]
    )
  end

  def update_params
    params.require(:order).permit(
      :customer_id,
      :staff_name,
      :order_status_id,
      :order_date,
      :payment_due_date,
      :payment_method,
      :project_name,
      :project_summary,
      :notes,
      :delivery_date,
      :delivery_address,
      order_items_attributes: [
        :id,
        :product_id,
        :unit_price,
        :quantity,
        :amount,
        :_destroy
      ]
    )
  end

  def payment_params
    params.require(:order).permit(
      :payment_date,
      :payment_notes,
      :order_status_id
    )
  end
end 
