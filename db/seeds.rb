# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# 案件ステータスの作成
order_statuses = [
  { name: '新規', code: 'new', display_order: 1, color: '#007bff', description: '新規案件' },
  { name: '進行中', code: 'in_progress', display_order: 2, color: '#ffc107', description: '進行中の案件' },
  { name: '完了', code: 'completed', display_order: 3, color: '#28a745', description: '完了した案件' },
  { name: 'キャンセル', code: 'cancelled', display_order: 4, color: '#dc3545', description: 'キャンセルされた案件' }
]

order_statuses.each do |status_data|
  OrderStatus.find_or_create_by!(code: status_data[:code]) do |status|
    status.assign_attributes(status_data)
  end
end

puts "案件ステータスのテストデータを投入しました。"

# 顧客マスタのテストデータ
customers = [
  {
    code: 'C001',
    name: '株式会社サンプル',
    company_name: '株式会社サンプル',
    industry: 'IT',
    established_date: '2010-04-01',
    capital: 10000000,
    representative_name: '山田太郎',
    employee_count: 50,
    business_description: 'システム開発、Webアプリケーション開発、ITコンサルティング',
    status: 'active',
    address: '東京都千代田区千代田1-1-1',
    phone: '03-1234-5678',
    email: 'info@sample.co.jp',
    payment_term: '月末締め翌月末払い',
    payment_method: '銀行振込',
    invoice_email: 'invoice@sample.co.jp',
    notes: '大手企業向けのシステム開発を得意とする',
    is_active: true
  },
  {
    code: 'C002',
    name: 'テスト商事株式会社',
    company_name: 'テスト商事株式会社',
    industry: '製造業',
    established_date: '2005-10-01',
    capital: 50000000,
    representative_name: '鈴木一郎',
    employee_count: 200,
    business_description: '電子部品の製造・販売、技術開発',
    status: 'active',
    address: '大阪府大阪市北区梅田2-2-2',
    phone: '06-1234-5678',
    email: 'info@test-shoji.co.jp',
    payment_term: '15日締め翌月末払い',
    payment_method: '銀行振込',
    invoice_email: 'billing@test-shoji.co.jp',
    notes: '自動車向け電子部品の製造を主力とする',
    is_active: true
  },
  {
    code: 'C003',
    name: 'デモ株式会社',
    company_name: 'デモ株式会社',
    industry: 'サービス業',
    established_date: '2018-01-15',
    capital: 3000000,
    representative_name: '佐藤花子',
    employee_count: 20,
    business_description: '人材派遣、業務請負、教育研修',
    status: 'prospect',
    address: '愛知県名古屋市中区栄3-3-3',
    phone: '052-123-4567',
    email: 'info@demo.co.jp',
    payment_term: '月末締め翌々月末払い',
    payment_method: 'クレジットカード',
    invoice_email: 'accounting@demo.co.jp',
    notes: 'IT人材の派遣を中心に展開',
    is_active: true
  },
  {
    code: 'C004',
    name: 'テックソリューション株式会社',
    company_name: 'テックソリューション株式会社',
    industry: 'IT',
    established_date: '2015-03-01',
    capital: 20000000,
    representative_name: '田中次郎',
    employee_count: 100,
    business_description: 'AI・機械学習、データ分析、クラウドサービス',
    status: 'active',
    address: '神奈川県横浜市西区みなとみらい4-4-4',
    phone: '045-123-4567',
    email: 'info@tech-solution.co.jp',
    payment_term: '月末締め翌月末払い',
    payment_method: '銀行振込',
    invoice_email: 'billing@tech-solution.co.jp',
    notes: 'AI技術を活用したソリューション開発',
    is_active: true
  },
  {
    code: 'C005',
    name: 'グリーンエナジー株式会社',
    company_name: 'グリーンエナジー株式会社',
    industry: '製造業',
    established_date: '2012-07-01',
    capital: 80000000,
    representative_name: '高橋美咲',
    employee_count: 150,
    business_description: '太陽光発電システム、蓄電池、省エネ設備',
    status: 'active',
    address: '福岡県福岡市博多区博多駅前5-5-5',
    phone: '092-123-4567',
    email: 'info@green-energy.co.jp',
    payment_term: '20日締め翌月末払い',
    payment_method: '銀行振込',
    invoice_email: 'accounting@green-energy.co.jp',
    notes: '再生可能エネルギー関連の設備製造',
    is_active: true
  }
]

# 顧客データの作成
customers.each do |customer_data|
  customer = Customer.find_or_create_by!(code: customer_data[:code]) do |customer|
    customer.assign_attributes(customer_data)
  end

  # 担当者情報の作成
  contacts = [
    {
      name: '田中次郎',
      position: '営業部長',
      phone_number: '090-1234-5678',
      email: 'tanaka@sample.co.jp',
      is_active: true
    },
    {
      name: '山本三郎',
      position: '技術部長',
      phone_number: '090-2345-6789',
      email: 'yamamoto@sample.co.jp',
      is_active: true
    }
  ]

  # contacts.each do |contact_data|
  #   customer.customer_contacts.find_or_create_by!(name: contact_data[:name]) do |contact|
  #     contact.assign_attributes(contact_data)
  #   end
  # end

  # メモの作成
  notes = [
    {
      content: '初回商談実施。システム更新のニーズあり。'
    },
    {
      content: '見積もり提出済み。予算内での実現可能性を検討中。'
    }
  ]

  # notes.each do |note_data|
  #   customer.customer_notes.create!(note_data)
  # end

  # 添付ファイルの作成（ダミーデータ）
  attachments = [
    {
      filename: 'company_profile.pdf',
      file_type: 'pdf',
      file_path: '/uploads/company_profile.pdf'
    },
    {
      filename: 'contract.docx',
      file_type: 'doc',
      file_path: '/uploads/contract.docx'
    }
  ]

  # attachments.each do |attachment_data|
  #   customer.customer_attachments.find_or_create_by!(filename: attachment_data[:filename]) do |attachment|
  #     attachment.assign_attributes(attachment_data)
  #   end
  # end
end

puts "顧客マスタのテストデータを投入しました。"

# 商品マスタのテストデータ
products = [
  {
    code: 'P001',
    name: 'Webサイト制作',
    unit_price: 300000,
    description: '企業向けWebサイトの制作サービス。レスポンシブデザイン、SEO対策、アクセス解析対応。',
    is_active: true,
    tax_rate: 10,
    supplier_name: '内製',
    cost_price: 150000,
    stock_quantity: 999,
    stock_threshold: 10
  },
  {
    code: 'P002',
    name: 'ECサイト構築',
    unit_price: 500000,
    description: 'オンラインショップの構築サービス。決済システム連携、在庫管理、顧客管理機能付き。',
    is_active: true,
    tax_rate: 10,
    supplier_name: '内製',
    cost_price: 250000,
    stock_quantity: 999,
    stock_threshold: 10
  },
  {
    code: 'P003',
    name: 'システム開発',
    unit_price: 1000000,
    description: '業務システムの開発サービス。要件定義から設計、開発、テスト、運用保守まで対応。',
    is_active: true,
    tax_rate: 10,
    supplier_name: '内製',
    cost_price: 500000,
    stock_quantity: 999,
    stock_threshold: 10
  },
  {
    code: 'P004',
    name: 'アプリ開発',
    unit_price: 800000,
    description: 'スマートフォンアプリの開発サービス。iOS/Android両対応、プッシュ通知、位置情報機能対応。',
    is_active: true,
    tax_rate: 10,
    supplier_name: '内製',
    cost_price: 400000,
    stock_quantity: 999,
    stock_threshold: 10
  },
  {
    code: 'P005',
    name: '保守運用',
    unit_price: 50000,
    description: 'システムの保守運用サービス。定期メンテナンス、障害対応、セキュリティ対策。',
    is_active: true,
    tax_rate: 10,
    supplier_name: '内製',
    cost_price: 25000,
    stock_quantity: 999,
    stock_threshold: 10
  },
  {
    code: 'P006',
    name: 'コンサルティング',
    unit_price: 150000,
    description: 'IT戦略のコンサルティングサービス。DX推進、システム選定、導入支援。',
    is_active: true,
    tax_rate: 10,
    supplier_name: '内製',
    cost_price: 75000,
    stock_quantity: 999,
    stock_threshold: 10
  },
  {
    code: 'P007',
    name: 'セキュリティ診断',
    unit_price: 200000,
    description: 'システムのセキュリティ診断サービス。脆弱性診断、ペネトレーションテスト、セキュリティ対策提案。',
    is_active: true,
    tax_rate: 10,
    supplier_name: '内製',
    cost_price: 100000,
    stock_quantity: 2,
    stock_threshold: 5
  },
  {
    code: 'P008',
    name: 'データ分析',
    unit_price: 300000,
    description: 'ビッグデータ分析サービス。データ収集、分析、可視化、レポーティング。',
    is_active: true,
    tax_rate: 10,
    supplier_name: '内製',
    cost_price: 150000,
    stock_quantity: 0,
    stock_threshold: 3
  }
]

# 商品データの作成
products.each do |product_data|
  Product.find_or_create_by!(code: product_data[:code]) do |product|
    product.assign_attributes(product_data)
  end
end

puts "商品マスタのテストデータを投入しました。"

# 案件のテストデータ
customers = Customer.where(is_active: true).limit(3)
order_statuses = OrderStatus.all
products = Product.where(is_active: true).limit(5)

# 過去6ヶ月分の案件を作成
(5.downto(0)).each do |i|
  month_start = Date.current.beginning_of_month - i.months
  
  # 各月に2-4件の案件を作成
  rand(2..4).times do
    customer = customers.sample
    next unless customer.present?
    order_status = order_statuses.sample
    order_date = month_start + rand(0..month_start.end_of_month.day - 1).days
    
    # order_numberを毎回ユニークに生成
    order_number = "O#{month_start.strftime('%Y%m')}#{rand(1000..9999)}#{Time.now.to_i}#{rand(100..999)}"
    # items_attributesを必ず1件以上作成
    n_items = rand(1..3)
    items_attributes = []
    n_items.times do
      product = products.sample
      next unless product.present?
      quantity = rand(1..3)
      items_attributes << {
        product_id: product.id,
        quantity: quantity,
        unit_price: product.unit_price,
        amount: quantity * product.unit_price
      }
    end
    next if items_attributes.empty?
    puts "Order: #{order_number}, customer: #{customer&.id}, items: #{items_attributes.inspect}"
    begin
      Order.create!(
        order_number: order_number,
        customer: customer,
        order_date: order_date,
        staff_name: '営業担当者',
        total_amount: 0,
        notes: "テスト案件 #{order_date.strftime('%Y年%m月')}",
        order_status: order_status,
        order_items_attributes: items_attributes
      )
    rescue => e
      puts "Order作成失敗: #{order_number}, customer: #{customer&.id}, items: #{items_attributes.size}, error: #{e.message}"
      puts "OrderItems: #{items_attributes.inspect}"
      puts e.backtrace.join("\n")
    end
  end
end

puts "案件のテストデータを投入しました。"

# 請求書のテストデータ
customers = Customer.where(is_active: true).limit(3)
products = Product.where(is_active: true).limit(5)

# 過去6ヶ月分の請求書を作成
(5.downto(0)).each do |i|
  month_start = Date.current.beginning_of_month - i.months
  
  # 各月に3-5件の請求書を作成
  rand(3..5).times do
    customer = customers.sample
    next unless customer.present?
    invoice_date = month_start + rand(0..month_start.end_of_month.day - 1).days
    payment_due_date = invoice_date + rand(30..60).days
    status = ['pending', 'paid'].sample
    invoice_number = "I#{month_start.strftime('%Y%m')}#{rand(1000..9999)}#{Time.now.to_i}#{rand(100..999)}"
    # items_attributesを必ず1件以上作成
    n_items = rand(1..4)
    items_attributes = []
    n_items.times do
      product = products.sample
      next unless product.present?
      quantity = rand(1..2)
      items_attributes << {
        product_code: product.code,
        product_name: product.name,
        unit_price: product.unit_price,
        quantity: quantity,
        tax_rate: product.tax_rate,
        amount: quantity * product.unit_price
      }
    end
    next if items_attributes.empty?
    puts "Invoice: #{invoice_number}, customer: #{customer&.id}, items: #{items_attributes.inspect}"
    begin
      Invoice.create!(
        invoice_number: invoice_number,
        invoice_date: invoice_date,
        customer_name: customer.name,
        customer_address: customer.address,
        subject: "システム開発費用",
        staff_name: '営業担当者',
        status: status,
        total_amount: 0,
        payment_due_date: payment_due_date,
        payment_method: customer.payment_method,
        notes: "テスト請求書 #{invoice_date.strftime('%Y年%m月')}",
        invoice_items_attributes: items_attributes
      )
    rescue => e
      puts "Invoice作成失敗: #{invoice_number}, customer: #{customer&.id}, items: #{items_attributes.size}, error: #{e.message}"
      puts "InvoiceItems: #{items_attributes.inspect}"
      puts e.backtrace.join("\n")
    end
  end
end

puts "請求書のテストデータを投入しました。"

# --- 以下、見積書・納品書・領収書も同様のロジックで追加する場合の雛形 ---
# 必要に応じてQuotation, DeliveryNote, Receiptの作成ロジックも同様に追加してください。

User.find_or_create_by!(email: "admin@example.com") do |user|
  user.password = "Password1!"
end
