class QuotationsController < ApplicationController
  before_action :set_quotation, only: [:show, :edit, :update, :destroy]

  def index
    @q = Quotation.ransack(params[:q])
    @quotations = @q.result(distinct: true).includes(:quotation_items).order(created_at: :desc).page(params[:page])
  end

  def show
  end

  def new
    @quotation = Quotation.new
    # 初期状態では商品行を作成しない
  end

  def edit
    # 一時保存または販売停止中の商品明細を除外
    @quotation.quotation_items.each do |item|
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
        @quotation = Quotation.new(quotation_params)
        @quotation.draft = true
        
        # 一時保存時は重複チェックのみ実行
        if @quotation.quotation_number.present?
          # 見積書番号が入力されている場合のみ重複チェック
          existing_quotation = Quotation.where(quotation_number: @quotation.quotation_number).where.not(id: @quotation.id).first
          if existing_quotation
            @quotation.errors.add(:quotation_number, 'この見積書番号は既に使用されています')
            render :new, status: :unprocessable_entity
            return
          end
        end
        
        @quotation.save!(validate: false)
        redirect_to quotations_path, notice: '一時保存しました'
        return
      rescue => e
        # データベース制約エラーの場合は日本語メッセージを表示
        if e.is_a?(ActiveRecord::RecordNotUnique) || e.message.include?('duplicate key value')
          redirect_to quotations_path, alert: '見積書番号が重複しています。別の見積書番号を入力してください。'
        else
          redirect_to quotations_path, alert: "一時保存に失敗しました: #{e.message}"
        end
        return
      end
    end
    
    # 通常の登録処理
    @quotation = Quotation.new(quotation_params)
    @quotation.draft = false  # 本保存として設定
    
    if @quotation.save
      redirect_to @quotation, notice: '見積書を作成しました。'
    else
      # エラー時に見積書番号をクリア
      @quotation.quotation_number = nil
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # 一時保存の場合
    if params[:save_draft].present?
      begin
        # 既存のレコードを一時保存として更新
        @quotation.assign_attributes(quotation_params)
        @quotation.draft = true
        
        # 一時保存時は重複チェックのみ実行
        if @quotation.quotation_number.present?
          # 見積書番号が入力されている場合のみ重複チェック
          existing_quotation = Quotation.where(quotation_number: @quotation.quotation_number).where.not(id: @quotation.id).first
          if existing_quotation
            @quotation.errors.add(:quotation_number, 'この見積書番号は既に使用されています')
            render :edit, status: :unprocessable_entity
            return
          end
        end
        
        @quotation.save!(validate: false)
        redirect_to quotations_path, notice: '一時保存しました'
        return
      rescue => e
        # データベース制約エラーの場合は日本語メッセージを表示
        if e.is_a?(ActiveRecord::RecordNotUnique) || e.message.include?('duplicate key value')
          redirect_to quotations_path, alert: '見積書番号が重複しています。別の見積書番号を入力してください。'
        else
          redirect_to quotations_path, alert: "一時保存に失敗しました: #{e.message}"
        end
        return
      end
    end
    
    # 通常の更新処理
    @quotation.assign_attributes(quotation_params)
    @quotation.draft = false  # 一時保存を解除
    
    if @quotation.save
      redirect_to @quotation, notice: '見積書を更新しました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @quotation.discard
    redirect_to quotations_path, notice: '見積書を削除しました。'
  end

  def print
    # 新規作成時のプレビュー（フォームデータから）
    if params[:quotation_data].present?
      quotation_data = JSON.parse(params[:quotation_data])
      @quotation = OpenStruct.new(
        quotation_number: quotation_data['quotation_number'].presence || '',
        quotation_date: quotation_data['quotation_date'].present? ? Date.parse(quotation_data['quotation_date']) : nil,
        customer_name: quotation_data['customer_name'].presence || '',
        customer_address: quotation_data['customer_address'].presence || '',
        subject: quotation_data['subject'].presence || '',
        staff_name: quotation_data['staff_name'].presence || '',
        valid_until: quotation_data['valid_until'].present? ? Date.parse(quotation_data['valid_until']) : nil,
        status: quotation_data['status'].presence || '',
        notes: quotation_data['notes'].presence || '',
        total_amount: quotation_data['total_amount'] || 0,
        quotation_items: quotation_data['items'].map { |item| OpenStruct.new(item) }
      )
    elsif params[:id].present?
      # 既存データのプレビュー
      @quotation = Quotation.includes(:quotation_items, :quotation_histories).find(params[:id])
    else
      # エラー処理
      redirect_to quotations_path, alert: 'プレビューに必要なデータが見つかりません。'
      return
    end
    
    render layout: 'print'
  end

  def download_pdf
    # 新規作成時のPDF（フォームデータから）
    if params[:quotation_data].present?
      quotation_data = JSON.parse(params[:quotation_data])
      @quotation = OpenStruct.new(
        quotation_number: quotation_data['quotation_number'].presence || '',
        quotation_date: quotation_data['quotation_date'].present? ? Date.parse(quotation_data['quotation_date']) : nil,
        customer_name: quotation_data['customer_name'].presence || '',
        customer_address: quotation_data['customer_address'].presence || '',
        subject: quotation_data['subject'].presence || '',
        staff_name: quotation_data['staff_name'].presence || '',
        valid_until: quotation_data['valid_until'].present? ? Date.parse(quotation_data['valid_until']) : nil,
        status: quotation_data['status'].presence || '',
        notes: quotation_data['notes'].presence || '',
        total_amount: quotation_data['total_amount'] || 0,
        quotation_items: quotation_data['items'].map { |item| OpenStruct.new(item) }
      )
    elsif params[:id].present?
      # 既存データのPDF
      @quotation = Quotation.includes(:quotation_items, :quotation_histories).find(params[:id])
    else
      # エラー処理
      redirect_to quotations_path, alert: 'PDFに必要なデータが見つかりません。'
      return
    end
    
    # PDFを生成
    pdf_content = WickedPdf.new.pdf_from_string(
      render_to_string(
        template: 'quotations/print',
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
    
    # ファイル名を設定
    filename = "quotation_#{@quotation.quotation_number.presence || 'new'}.pdf"
    
    # PDFをダウンロード
    send_data pdf_content,
              filename: filename,
              type: 'application/pdf',
              disposition: 'attachment'
  end

  def export
    @quotations = Quotation.all
    respond_to do |format|
      format.csv do
        headers['Content-Disposition'] = "attachment; filename=\"quotations-#{Time.current.strftime('%Y%m%d')}.csv\""
        headers['Content-Type'] ||= 'text/csv'
      end
    end
  end

  def import
    # CSVインポート機能の実装
    redirect_to quotations_path, notice: '見積書データをインポートしました。'
  end

  def bulk_delete
    quotation_ids = params[:item_ids] || []
    deleted_count = 0
    error_count = 0

    quotation_ids.each do |quotation_id|
      quotation = Quotation.find(quotation_id)
      
      if quotation.discard
        deleted_count += 1
      else
        error_count += 1
      end
    end

    if error_count > 0
      redirect_to quotations_path, alert: "#{deleted_count}件削除しました。#{error_count}件は削除できませんでした。"
    else
      redirect_to quotations_path, notice: "#{deleted_count}件の見積書を削除しました"
    end
  end

  def search_products
    @products = Product.where(draft: false, is_active: true).where("code LIKE ? OR name LIKE ?", "%#{params[:q]}%", "%#{params[:q]}%").limit(10)
    render json: @products.map { |product| { id: product.id, code: product.code, name: product.name, unit_price: product.unit_price, tax_rate: product.tax_rate } }
  end

  def copy_to_delivery_note
    @quotation = Quotation.includes(:quotation_items).find(params[:id])
    
    # 見積書の情報を基に納品書を作成
    @delivery_note = DeliveryNote.new(
      delivery_date: Date.today,
      status: 'pending',
      customer_name: @quotation.customer_name,
      customer_address: @quotation.customer_address,
      subject: @quotation.subject,
      staff_name: @quotation.staff_name,
      notes: @quotation.notes,
      draft: false
    )
    
    # 商品明細をコピー
    @quotation.quotation_items.each do |item|
      @delivery_note.delivery_note_items.build(
        product_code: item.product_code,
        product_name: item.product_name,
        unit_price: item.unit_price,
        quantity: item.quantity,
        amount: item.amount,
        tax_rate: item.tax_rate
      )
    end
    
    if @delivery_note.save(validate: false)
      # 見積書からのコピー履歴を追加
      @delivery_note.delivery_note_histories.create!(
        action: "見積書からコピー"
      )
      redirect_to @delivery_note, notice: '見積書の情報を基に納品書を作成しました'
    else
      Rails.logger.error "納品書作成エラー: #{@delivery_note.errors.full_messages}"
      redirect_to @quotation, alert: "納品書の作成に失敗しました: #{@delivery_note.errors.full_messages.join(', ')}"
    end
  end

  def copy_to_invoice
    @quotation = Quotation.includes(:quotation_items).find(params[:id])
    
    # 見積書の情報を基に請求書を作成
    @invoice = Invoice.new(
      invoice_date: Date.today,
      status: 'pending',
      customer_name: @quotation.customer_name,
      customer_address: @quotation.customer_address,
      subject: @quotation.subject,
      staff_name: @quotation.staff_name,
      notes: @quotation.notes,
      draft: false
    )
    
    # 商品明細をコピー
    @quotation.quotation_items.each do |item|
      @invoice.invoice_items.build(
        product_code: item.product_code,
        product_name: item.product_name,
        unit_price: item.unit_price,
        quantity: item.quantity,
        amount: item.amount,
        tax_rate: item.tax_rate
      )
    end
    
    if @invoice.save(validate: false)
      # 見積書からのコピー履歴を追加
      @invoice.invoice_histories.create!(
        action: "見積書からコピー"
      )
      redirect_to @invoice, notice: '見積書の情報を基に請求書を作成しました'
    else
      Rails.logger.error "請求書作成エラー: #{@invoice.errors.full_messages}"
      redirect_to @quotation, alert: "請求書の作成に失敗しました: #{@invoice.errors.full_messages.join(', ')}"
    end
  end

  def copy_to_receipt
    @quotation = Quotation.includes(:quotation_items).find(params[:id])
    
    # 見積書の情報を基に領収書を作成
    @receipt = Receipt.new(
      issue_date: Date.today,
      status: 'pending',
      customer_name: @quotation.customer_name,
      customer_address: @quotation.customer_address,
      subject: @quotation.subject,
      staff_name: @quotation.staff_name,
      notes: @quotation.notes,
      draft: false
    )
    
    # 商品明細をコピー
    @quotation.quotation_items.each do |item|
      @receipt.receipt_items.build(
        product_code: item.product_code,
        product_name: item.product_name,
        unit_price: item.unit_price,
        quantity: item.quantity,
        amount: item.amount,
        tax_rate: item.tax_rate
      )
    end
    
    if @receipt.save(validate: false)
      # 見積書からのコピー履歴を追加
      @receipt.receipt_histories.create!(
        action: "見積書からコピー"
      )
      redirect_to @receipt, notice: '見積書の情報を基に領収書を作成しました'
    else
      Rails.logger.error "領収書作成エラー: #{@receipt.errors.full_messages}"
      redirect_to @quotation, alert: "領収書の作成に失敗しました: #{@receipt.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_quotation
    @quotation = Quotation.includes(:quotation_items, :quotation_histories).find(params[:id])
  end



  def quotation_params
    params.require(:quotation).permit(
      :quotation_number,
      :quotation_date,
      :customer_name,
      :customer_address,
      :subject,
      :staff_name,
      :valid_until,
      :status,
      :notes,
      :total_amount,
      :draft,
      quotation_items_attributes: [
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
end 