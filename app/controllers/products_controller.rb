class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update, :destroy]

  def index
    @products = Product.all

    # 検索条件の適用
    if params[:name].present?
      @products = @products.where('name LIKE ?', "%#{params[:name]}%")
    end

    if params[:code].present?
      @products = @products.where('code LIKE ?', "%#{params[:code]}%")
    end

    if params[:status].present?
      if params[:status] == '販売中'
        @products = @products.where(is_active: true)
      elsif params[:status] == '販売停止'
        @products = @products.where(is_active: false)
      end
    end

    # ソート機能
    case params[:sort]
    when 'name_asc'
      @products = @products.order(:name)
    when 'name_desc'
      @products = @products.order(name: :desc)
    when 'price_asc'
      @products = @products.order(:unit_price)
    when 'price_desc'
      @products = @products.order(unit_price: :desc)
    else
      @products = @products.order(:created_at)
    end

    @total_count = @products.count
    @products = @products.page(params[:page]).per(20)
  end

  def show
    # 最近の案件データを取得
    @recent_orders = @product.order_items.includes(:order)
                            .where.not(orders: { id: nil })
                            .order('orders.order_date DESC')
                            .limit(5)
                            .map do |item|
      next unless item.order # orderがnilの場合はスキップ
      {
        id: item.order.id,
        order_number: item.order.order_number,
        total_amount: item.order.total_amount,
        order_date: item.order.order_date
      }
    end.compact # nilを除去

    respond_to do |format|
      format.html
      format.json do
        if @product
          render json: { 
            id: @product.id,
            name: @product.name,
            price: @product.unit_price,
            description: @product.description
          }
        else
          render json: { error: '商品が見つかりません' }, status: :not_found
        end
      end
    end
  end

  def new
    @product = Product.new
  end

  def edit
  end

  def create
    # 一時保存の場合
    if params[:save_draft].present?
      begin
        # 新しい一時保存データを作成
        @product = Product.new(product_params)
        @product.draft = true
        
        # 一時保存時は重複チェックのみ実行
        if @product.code.present?
          # 商品コードが入力されている場合のみ重複チェック
          existing_product = Product.where(code: @product.code).where.not(id: @product.id).first
          if existing_product
            @product.errors.add(:code, 'この商品コードは既に使用されています')
            render :new, status: :unprocessable_entity
            return
          end
        end
        
        @product.save!(validate: false)
        redirect_to products_path, notice: '一時保存しました'
        return
      rescue => e
        redirect_to products_path, alert: "一時保存に失敗しました: #{e.message}"
        return
      end
    end
    
    # 通常の登録処理
    @product = Product.new(product_params)
    @product.draft = false  # 本保存として設定

    if @product.save
      redirect_to @product, notice: '商品を登録しました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # 一時保存の場合
    if params[:save_draft].present?
      begin
        # 既存のレコードを一時保存として更新
        @product.assign_attributes(product_params)
        @product.draft = true
        
        # 一時保存時は重複チェックのみ実行
        if @product.code.present?
          # 商品コードが入力されている場合のみ重複チェック
          existing_product = Product.where(code: @product.code).where.not(id: @product.id).first
          if existing_product
            @product.errors.add(:code, 'この商品コードは既に使用されています')
            render :edit, status: :unprocessable_entity
            return
          end
        end
        
        @product.save!(validate: false)
        redirect_to products_path, notice: '一時保存しました'
        return
      rescue => e
        redirect_to products_path, alert: "一時保存に失敗しました: #{e.message}"
        return
      end
    end
    
    # 通常の更新処理
    @product.assign_attributes(product_params)
    @product.draft = false  # 一時保存を解除
    
    if @product.save
      # 削除チェックボックスがオンにされた添付ファイルを削除
      if params[:purge_attachments].present?
        attachment_ids_to_purge = params[:purge_attachments].keys
        
        # 商品画像の削除
        if @product.image.attached? && attachment_ids_to_purge.include?(@product.image.id.to_s)
          @product.image.purge
        end
        
        # 添付ファイルの削除
        attachments_to_purge = @product.attachments.where(id: attachment_ids_to_purge)
        attachments_to_purge.each(&:purge)
      end

      redirect_to @product, notice: '商品を更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @product.has_orders?
      redirect_to products_path, alert: 'この商品は案件に紐づいているため削除できません。先に案件を削除してください。'
    else
      @product.discard
      redirect_to products_url, notice: '商品を削除しました'
    end
  end

  def bulk_delete
    product_ids = params[:item_ids] || []
    deleted_count = 0
    error_count = 0

    product_ids.each do |product_id|
      product = Product.find(product_id)
      
      # 案件に紐づいているかチェック
      if product.has_orders?
        error_count += 1
        next
      end
      
      if product.discard
        deleted_count += 1
      else
        error_count += 1
      end
    end

    if error_count > 0
      redirect_to products_path, alert: "#{deleted_count}件削除しました。#{error_count}件は案件に紐づいているため削除できませんでした。"
    else
      redirect_to products_path, notice: "#{deleted_count}件の商品を削除しました"
    end
  end

  def export
    @products = Product.all
    respond_to do |format|
      format.csv { send_data @products.to_csv, filename: "products-#{Time.current.strftime('%Y%m%d')}.csv" }
    end
  end

  def import
    # 商品データのインポート
  end

  def info
    @product = Product.find(params[:id])
    render json: {
      unit_price: @product.unit_price
    }
  end

  private

  def set_product
    @product = Product.with_discarded.find_by(id: params[:id])
  end

  def product_params
    params.require(:product).permit(
      :name, :code, :unit_price, :description, :is_active, :notes,
      :cost_price, :stock_quantity, :stock_threshold, :tax_rate,
      :supplier_name, :supplier_contact, :supplier_phone, :supplier_email,
      :image
    )
  end
end 