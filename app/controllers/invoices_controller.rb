class InvoicesController < ApplicationController
  before_action :set_invoice, only: [:show, :edit, :update, :destroy]

  def index
    @q = Invoice.ransack(params[:q])
    @invoices = @q.result(distinct: true).includes(:invoice_items).order(created_at: :desc).page(params[:page])
  end

  def show
  end

  def new
    @invoice = Invoice.new(invoice_date: Date.today, transaction_date: Date.today, status: 'pending')
    prefill_from_order(@invoice) if params[:order_id].present?
  end

  def edit
    # 一時保存または販売停止中の商品明細を除外
    @invoice.invoice_items.each do |item|
      product = Product.find_by(code: item.product_code, name: item.product_name)
      if product && (product.draft? || !product.is_active?)
        item.mark_for_destruction
      end
    end
  end

  def create
    # 一時保存の場合
    if params[:save_draft].present?
      begin
        # 新しい一時保存データを作成
        @invoice = Invoice.new(invoice_params)
        @invoice.draft = true
        # ステータスはユーザーが選択した値を保持
        
        # 一時保存時は重複チェックのみ実行
        if @invoice.invoice_number.present?
          # 請求書番号が入力されている場合のみ重複チェック
          existing_invoice = Invoice.where(invoice_number: @invoice.invoice_number).where.not(id: @invoice.id).first
          if existing_invoice
            @invoice.errors.add(:invoice_number, 'この請求書番号は既に使用されています')
            render :new, status: :unprocessable_entity
            return
          end
        end
        
        @invoice.save!(validate: false)
        redirect_to invoices_path, notice: '一時保存しました'
        return
      rescue => e
        redirect_to invoices_path, alert: "一時保存に失敗しました: #{e.message}"
        return
      end
    end
    
    # 通常の登録処理
    @invoice = Invoice.new(invoice_params)
    @invoice.draft = false  # 本保存として設定
    
    if @invoice.save
      redirect_to @invoice, notice: '請求書を作成しました。'
    else
      # エラー時に請求書番号をクリア
      @invoice.invoice_number = nil
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # 一時保存の場合
    if params[:save_draft].present?
      begin
        # 既存のレコードを一時保存として更新
        @invoice.assign_attributes(invoice_params)
        @invoice.draft = true
        # ステータスはユーザーが選択した値を保持
        
        # 一時保存時は重複チェックのみ実行
        if @invoice.invoice_number.present?
          # 請求書番号が入力されている場合のみ重複チェック
          existing_invoice = Invoice.where(invoice_number: @invoice.invoice_number).where.not(id: @invoice.id).first
          if existing_invoice
            @invoice.errors.add(:invoice_number, 'この請求書番号は既に使用されています')
            render :edit, status: :unprocessable_entity
            return
          end
        end
        
        @invoice.save!(validate: false)
        redirect_to invoices_path, notice: '一時保存しました'
        return
      rescue => e
        redirect_to invoices_path, alert: "一時保存に失敗しました: #{e.message}"
        return
      end
    end
    
    # 通常の更新処理
    @invoice.assign_attributes(invoice_params)
    @invoice.draft = false  # 一時保存を解除
    
    if @invoice.save
      redirect_to @invoice, notice: '請求書を更新しました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @invoice.discard
    redirect_to invoices_path, notice: '請求書を削除しました。'
  end



  def print
    if params[:invoice_data].present?
      invoice_data = JSON.parse(params[:invoice_data])
      @invoice = OpenStruct.new(
        invoice_number: invoice_data['invoice_number'].presence || '',
        invoice_date: invoice_data['invoice_date'].present? ? Date.parse(invoice_data['invoice_date']) : nil,
        transaction_date: invoice_data['transaction_date'].present? ? Date.parse(invoice_data['transaction_date']) : nil,
        customer_name: invoice_data['customer_name'].presence || '',
        customer_address: invoice_data['customer_address'].presence || '',
        subject: invoice_data['subject'].presence || '',
        staff_name: invoice_data['staff_name'].presence || '',
        payment_due_date: invoice_data['payment_due_date'].present? ? Date.parse(invoice_data['payment_due_date']) : nil,
        status: invoice_data['status'].presence || '',
        notes: invoice_data['notes'].presence || '',
        total_amount: invoice_data['total_amount'] || 0,
        payment_method: invoice_data['payment_method'].presence || '',
        invoice_items: invoice_data['items'].map { |item| OpenStruct.new(item) }
      )
    elsif params[:id].present?
      @invoice = Invoice.includes(:invoice_items, :invoice_histories).find(params[:id])
    else
      redirect_to invoices_path, alert: 'プレビューに必要なデータが見つかりません。'
      return
    end
    render layout: 'print'
  end

  def download_pdf
    if params[:invoice_data].present?
      invoice_data = JSON.parse(params[:invoice_data])
      @invoice = OpenStruct.new(
        invoice_number: invoice_data['invoice_number'].presence || '',
        invoice_date: invoice_data['invoice_date'].present? ? Date.parse(invoice_data['invoice_date']) : nil,
        transaction_date: invoice_data['transaction_date'].present? ? Date.parse(invoice_data['transaction_date']) : nil,
        customer_name: invoice_data['customer_name'].presence || '',
        customer_address: invoice_data['customer_address'].presence || '',
        subject: invoice_data['subject'].presence || '',
        staff_name: invoice_data['staff_name'].presence || '',
        payment_due_date: invoice_data['payment_due_date'].present? ? Date.parse(invoice_data['payment_due_date']) : nil,
        status: invoice_data['status'].presence || '',
        notes: invoice_data['notes'].presence || '',
        total_amount: invoice_data['total_amount'] || 0,
        payment_method: invoice_data['payment_method'].presence || '',
        invoice_items: invoice_data['items'].map { |item| OpenStruct.new(item) }
      )
    elsif params[:id].present?
      @invoice = Invoice.includes(:invoice_items, :invoice_histories).find(params[:id])
    else
      redirect_to invoices_path, alert: 'PDFダウンロードに必要なデータが見つかりません。'
      return
    end

    pdf_content = WickedPdf.new.pdf_from_string(
      render_to_string(
        template: 'invoices/print',
        layout: 'pdf',
        formats: [:html]
      ),
      page_size: 'A4',
      orientation: 'portrait',
      margin: { top: '20mm', bottom: '20mm', left: '20mm', right: '20mm' },
      disable_smart_shrinking: false,
      default_font: 'Noto Sans JP',
      wkhtmltopdf: [
        '--default-font', 'Noto Sans JP',
        '--encoding', 'UTF-8',
        '--no-stop-slow-scripts',
        '--javascript-delay', '1000',
        '--load-error-handling', 'ignore',
        '--load-media-error-handling', 'ignore'
      ]
    )
    filename = "invoice_#{@invoice.invoice_number.presence || 'new'}.pdf"
    send_data pdf_content,
              filename: filename,
              type: 'application/pdf',
              disposition: 'attachment'
  end

  def search_products
    @products = Product.where(draft: false, is_active: true).where("code LIKE ? OR name LIKE ?", "%#{params[:q]}%", "%#{params[:q]}%").limit(10)
    render json: @products.map { |product| { id: product.id, code: product.code, name: product.name, unit_price: product.unit_price, tax_rate: product.tax_rate } }
  end

  private

  def set_invoice
    @invoice = Invoice.includes(:invoice_items, :invoice_histories).find(params[:id])
  end



  def invoice_params
    params.require(:invoice).permit(
      :invoice_number,
      :invoice_date,
      :transaction_date,
      :customer_name,
      :customer_address,
      :subject,
      :staff_name,
      :payment_due_date,
      :payment_method,
      :status,
      :notes,
      :total_amount,
      :draft,
      invoice_items_attributes: [
        :id,
        :product_code,
        :product_name,
        :unit_price,
        :quantity,
        :amount,
        :tax_rate,
        :_destroy
      ]
    )
  end

  def prefill_from_order(invoice)
    order = current_company.orders.includes(:customer, order_items: :product).find_by(id: params[:order_id])
    return if order.blank?

    invoice.assign_attributes(
      customer_name: order.customer&.name,
      customer_address: order.customer&.address,
      subject: order.project_name.presence || order.display_order_number,
      staff_name: order.staff_name,
      payment_due_date: order.payment_due_date,
      payment_method: Order.payment_method_text(order.payment_method),
      notes: order.project_summary
    )
    order.order_items.each do |item|
      invoice.invoice_items.build(
        product_code: item.product&.code,
        product_name: item.product&.name,
        unit_price: item.unit_price,
        quantity: item.quantity,
        amount: item.amount,
        tax_rate: item.product&.tax_rate
      )
    end
  end
end 
