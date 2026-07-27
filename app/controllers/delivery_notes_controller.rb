class DeliveryNotesController < ApplicationController
  before_action :set_delivery_note, only: [:show, :edit, :update, :destroy]

  def index
    @q = DeliveryNote.kept.ransack(params[:q])
    @delivery_notes = @q.result.includes(:delivery_note_items).order(created_at: :desc).page(params[:page])
  end

  def show
  end

  def new
    @delivery_note = DeliveryNote.new(delivery_date: Date.today, transaction_date: Date.today, status: 'pending')
    prefill_from_order(@delivery_note) if params[:order_id].present?
  end

  def edit
    # 一時保存または販売停止中の商品明細を除外
    @delivery_note.delivery_note_items.each do |item|
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
        @delivery_note = DeliveryNote.new(delivery_note_params)
        @delivery_note.draft = true
        # ステータスはユーザーが選択した値を保持
        
        # 一時保存時は重複チェックのみ実行
        if @delivery_note.delivery_number.present?
          # 納品書番号が入力されている場合のみ重複チェック
          existing_delivery_note = DeliveryNote.where(delivery_number: @delivery_note.delivery_number).where.not(id: @delivery_note.id).first
          if existing_delivery_note
            @delivery_note.errors.add(:delivery_number, 'この納品書番号は既に使用されています')
            render :new, status: :unprocessable_entity
            return
          end
        end
        
        @delivery_note.save!(validate: false)
        redirect_to delivery_notes_path, notice: '一時保存しました'
        return
      rescue => e
        # データベース制約エラーの場合は日本語メッセージを表示
        if e.is_a?(ActiveRecord::RecordNotUnique) || e.message.include?('duplicate key value')
          redirect_to delivery_notes_path, alert: '納品書番号が重複しています。別の納品書番号を入力してください。'
        else
          redirect_to delivery_notes_path, alert: "一時保存に失敗しました: #{e.message}"
        end
        return
      end
    end
    
    # 通常の登録処理
    @delivery_note = DeliveryNote.new(delivery_note_params)
    @delivery_note.draft = false  # 本保存として設定
    
    if @delivery_note.save
      redirect_to @delivery_note, notice: '納品書を作成しました。'
    else
      # エラー時に納品書番号をクリア
      @delivery_note.delivery_number = nil
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # 一時保存の場合
    if params[:save_draft].present?
      begin
        # 既存のレコードを一時保存として更新
        @delivery_note.assign_attributes(delivery_note_params)
        @delivery_note.draft = true
        # ステータスはユーザーが選択した値を保持
        
        # 一時保存時は重複チェックのみ実行
        if @delivery_note.delivery_number.present?
          # 納品書番号が入力されている場合のみ重複チェック
          existing_delivery_note = DeliveryNote.where(delivery_number: @delivery_note.delivery_number).where.not(id: @delivery_note.id).first
          if existing_delivery_note
            @delivery_note.errors.add(:delivery_number, 'この納品書番号は既に使用されています')
            render :edit, status: :unprocessable_entity
            return
          end
        end
        
        @delivery_note.save!(validate: false)
        redirect_to delivery_notes_path, notice: '一時保存しました'
        return
      rescue => e
        # データベース制約エラーの場合は日本語メッセージを表示
        if e.is_a?(ActiveRecord::RecordNotUnique) || e.message.include?('duplicate key value')
          redirect_to delivery_notes_path, alert: '納品書番号が重複しています。別の納品書番号を入力してください。'
        else
          redirect_to delivery_notes_path, alert: "一時保存に失敗しました: #{e.message}"
        end
        return
      end
    end
    
    # 通常の更新処理
    @delivery_note.assign_attributes(delivery_note_params)
    @delivery_note.draft = false  # 一時保存を解除
    
    if @delivery_note.save
      redirect_to @delivery_note, notice: '納品書を更新しました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @delivery_note.discard
    redirect_to delivery_notes_path, notice: '納品書を削除しました。'
  end

  def print
    # 新規作成時のプレビュー（フォームデータから）
    if params[:delivery_note_data].present?
      delivery_note_data = JSON.parse(params[:delivery_note_data])
      @delivery_note = OpenStruct.new(
        delivery_number: delivery_note_data['delivery_number'].presence || '',
        delivery_date: delivery_note_data['delivery_date'].present? ? Date.parse(delivery_note_data['delivery_date']) : nil,
        transaction_date: delivery_note_data['transaction_date'].present? ? Date.parse(delivery_note_data['transaction_date']) : nil,
        customer_name: delivery_note_data['customer_name'].presence || '',
        customer_address: delivery_note_data['customer_address'].presence || '',
        subject: delivery_note_data['subject'].presence || '',
        staff_name: delivery_note_data['staff_name'].presence || '',
        valid_until: delivery_note_data['valid_until'].present? ? Date.parse(delivery_note_data['valid_until']) : nil,
        status: delivery_note_data['status'].presence || '',
        notes: delivery_note_data['notes'].presence || '',
        total_amount: delivery_note_data['total_amount'] || 0,
        delivery_note_items: delivery_note_data['items'].map { |item| OpenStruct.new(item) }
      )
    elsif params[:id].present?
      # 既存データのプレビュー
      @delivery_note = DeliveryNote.includes(:delivery_note_items).find(params[:id])
    else
      # エラー処理
      redirect_to delivery_notes_path, alert: 'プレビューに必要なデータが見つかりません。'
      return
    end
    
    render layout: 'print'
  end

  def download_pdf
    # 新規作成時のPDF（フォームデータから）
    if params[:delivery_note_data].present?
      delivery_note_data = JSON.parse(params[:delivery_note_data])
      @delivery_note = OpenStruct.new(
        delivery_number: delivery_note_data['delivery_number'].presence || '',
        delivery_date: delivery_note_data['delivery_date'].present? ? Date.parse(delivery_note_data['delivery_date']) : nil,
        transaction_date: delivery_note_data['transaction_date'].present? ? Date.parse(delivery_note_data['transaction_date']) : nil,
        customer_name: delivery_note_data['customer_name'].presence || '',
        customer_address: delivery_note_data['customer_address'].presence || '',
        subject: delivery_note_data['subject'].presence || '',
        staff_name: delivery_note_data['staff_name'].presence || '',
        valid_until: delivery_note_data['valid_until'].present? ? Date.parse(delivery_note_data['valid_until']) : nil,
        status: delivery_note_data['status'].presence || '',
        notes: delivery_note_data['notes'].presence || '',
        total_amount: delivery_note_data['total_amount'] || 0,
        delivery_note_items: delivery_note_data['items'].map { |item| OpenStruct.new(item) }
      )
    elsif params[:id].present?
      # 既存データのPDF
      @delivery_note = DeliveryNote.includes(:delivery_note_items).find(params[:id])
    else
      # エラー処理
      redirect_to delivery_notes_path, alert: 'PDFに必要なデータが見つかりません。'
      return
    end
    
    # PDFを生成
    pdf_content = WickedPdf.new.pdf_from_string(
      render_to_string(
        template: 'delivery_notes/print',
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
    filename = "delivery_note_#{@delivery_note.delivery_number.presence || 'new'}.pdf"
    
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

  def set_delivery_note
    @delivery_note = DeliveryNote.includes(:delivery_note_items, :delivery_note_histories).find(params[:id])
  end



  def delivery_note_params
    params.require(:delivery_note).permit(
      :delivery_number, :delivery_date, :transaction_date, :customer_name, :customer_address, :subject, :staff_name, :status, :notes, :valid_until, :draft,
      delivery_note_items_attributes: [
        :id, :product_code, :product_name, :unit_price, :quantity, :amount, :tax_rate, :_destroy
      ]
    )
  end

  def prefill_from_order(delivery_note)
    order = current_company.orders.includes(:customer, order_items: :product).find_by(id: params[:order_id])
    return if order.blank?

    delivery_note.assign_attributes(
      delivery_date: order.delivery_date || Date.current,
      transaction_date: order.delivery_date || Date.current,
      customer_name: order.customer&.name,
      customer_address: order.customer&.address,
      subject: order.project_name.presence || order.display_order_number,
      staff_name: order.staff_name,
      notes: order.project_summary
    )
    order.order_items.each do |item|
      delivery_note.delivery_note_items.build(
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
