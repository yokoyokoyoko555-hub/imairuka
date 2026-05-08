class ReceiptsController < ApplicationController
  before_action :set_receipt, only: [:show, :edit, :update, :destroy, :print, :download_pdf]

  def index
    @q = Receipt.kept.ransack(params[:q])
    @receipts = @q.result.includes(:receipt_items).order(created_at: :desc).page(params[:page])
  end

  def show
  end

  def new
    @receipt = Receipt.new(issue_date: Date.today, status: 'pending')
  end

  def edit
    # 一時保存または販売停止中の商品明細を除外
    @receipt.receipt_items.each do |item|
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
        @receipt = Receipt.new(receipt_params)
        @receipt.draft = true
        @receipt.status = 'pending'  # 一時保存時はpendingに設定
        
        # 一時保存時は重複チェックのみ実行
        if @receipt.receipt_number.present?
          # 領収書番号が入力されている場合のみ重複チェック
          existing_receipt = Receipt.where(receipt_number: @receipt.receipt_number).where.not(id: @receipt.id).first
          if existing_receipt
            @receipt.errors.add(:receipt_number, 'この領収書番号は既に使用されています')
            render :new, status: :unprocessable_entity
            return
          end
        end
        
        @receipt.save!(validate: false)
        redirect_to receipts_path, notice: '一時保存しました'
        return
      rescue => e
        redirect_to receipts_path, alert: "一時保存に失敗しました: #{e.message}"
        return
      end
    end
    
    # 通常の登録処理
    @receipt = Receipt.new(receipt_params)
    @receipt.draft = false  # 本保存として設定
    
    if @receipt.save
      redirect_to @receipt, notice: '領収書を作成しました。'
    else
      # エラー時に領収書番号をクリア
      @receipt.receipt_number = nil
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # 一時保存の場合
    if params[:save_draft].present?
      begin
        # 既存のレコードを一時保存として更新
        @receipt.assign_attributes(receipt_params)
        @receipt.draft = true
        @receipt.status = 'pending'  # 一時保存時はpendingに設定
        
        # 一時保存時は重複チェックのみ実行
        if @receipt.receipt_number.present?
          # 領収書番号が入力されている場合のみ重複チェック
          existing_receipt = Receipt.where(receipt_number: @receipt.receipt_number).where.not(id: @receipt.id).first
          if existing_receipt
            @receipt.errors.add(:receipt_number, 'この領収書番号は既に使用されています')
            render :edit, status: :unprocessable_entity
            return
          end
        end
        
        @receipt.save!(validate: false)
        redirect_to receipts_path, notice: '一時保存しました'
        return
      rescue => e
        redirect_to receipts_path, alert: "一時保存に失敗しました: #{e.message}"
        return
      end
    end
    
    # 通常の更新処理
    @receipt.assign_attributes(receipt_params)
    @receipt.draft = false  # 一時保存を解除
    
    if @receipt.save
      redirect_to @receipt, notice: '領収書を更新しました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @receipt.discard
    redirect_to receipts_path, notice: '領収書を削除しました。'
  end

  def print
    # 新規作成時のプレビュー（フォームデータから）
    if params[:receipt_data].present?
      receipt_data = JSON.parse(params[:receipt_data])
      @receipt = OpenStruct.new(
        receipt_number: receipt_data['receipt_number'].presence || '',
        issue_date: receipt_data['issue_date'].present? ? Date.parse(receipt_data['issue_date']) : nil,
        customer_name: receipt_data['customer_name'].presence || '',
        customer_address: receipt_data['customer_address'].presence || '',
        subject: receipt_data['subject'].presence || '',
        staff_name: receipt_data['staff_name'].presence || '',
        payment_method: receipt_data['payment_method'].presence || '',
        payment_date: receipt_data['payment_date'].present? ? Date.parse(receipt_data['payment_date']) : nil,
        status: receipt_data['status'].presence || '',
        notes: receipt_data['notes'].presence || '',
        total_amount: receipt_data['total_amount'] || 0,
        receipt_items: receipt_data['items'].map { |item| OpenStruct.new(item) }
      )
    elsif params[:id].present?
      # 既存データのプレビュー
      @receipt = Receipt.includes(:receipt_items, :receipt_histories).find(params[:id])
    else
      # エラー処理
      redirect_to receipts_path, alert: 'プレビューに必要なデータが見つかりません。'
      return
    end
    
    render layout: 'print'
  end

  def download_pdf
    # 新規作成時のPDF（フォームデータから）
    if params[:receipt_data].present?
      receipt_data = JSON.parse(params[:receipt_data])
      @receipt = OpenStruct.new(
        receipt_number: receipt_data['receipt_number'].presence || '',
        issue_date: receipt_data['issue_date'].present? ? Date.parse(receipt_data['issue_date']) : nil,
        customer_name: receipt_data['customer_name'].presence || '',
        customer_address: receipt_data['customer_address'].presence || '',
        subject: receipt_data['subject'].presence || '',
        staff_name: receipt_data['staff_name'].presence || '',
        payment_method: receipt_data['payment_method'].presence || '',
        payment_date: receipt_data['payment_date'].present? ? Date.parse(receipt_data['payment_date']) : nil,
        status: receipt_data['status'].presence || '',
        notes: receipt_data['notes'].presence || '',
        total_amount: receipt_data['total_amount'] || 0,
        receipt_items: receipt_data['items'].map { |item| OpenStruct.new(item) }
      )
    elsif params[:id].present?
      # 既存データのPDF
      @receipt = Receipt.includes(:receipt_items, :receipt_histories).find(params[:id])
    else
      # エラー処理
      redirect_to receipts_path, alert: 'PDFに必要なデータが見つかりません。'
      return
    end
    
    # PDFを生成
    pdf_content = WickedPdf.new.pdf_from_string(
      render_to_string(
        template: 'receipts/print',
        layout: 'pdf',
        formats: [:html]
      ),
      page_size: 'A4',
      orientation: 'portrait',
      margin: { top: '20mm', bottom: '20mm', left: '20mm', right: '20mm' },
      disable_smart_shrinking: false,
      enable_local_file_access: true,
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
    filename = "receipt_#{@receipt.receipt_number.presence || 'new'}.pdf"
    
    # PDFをダウンロード
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

  def set_receipt
    @receipt = Receipt.includes(:receipt_items, :receipt_histories).find(params[:id]) if params[:id].present?
  end



  def receipt_params
    params.require(:receipt).permit(
      :receipt_number, :issue_date, :customer_name, :customer_address, :subject, :staff_name, :status, :notes, :total_amount, :valid_until, :draft,
      receipt_items_attributes: [
        :id, :product_code, :product_name, :unit_price, :quantity, :amount, :tax_rate, :_destroy
      ]
    )
  end
end 