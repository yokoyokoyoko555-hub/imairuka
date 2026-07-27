company = User.find_by(email: "admin@example.com")&.company || Company.first
raise "No company found. Create a company and admin user first." unless company

Current.company = company
admin = company.users.find_by(email: "admin@example.com") || company.users.first
raise "No user found for #{company.name}." unless admin

ActiveRecord::Base.transaction do
  PaymentRecord.unscoped.where(company_id: company.id).delete_all
  OrderAssignment.unscoped.where(company_id: company.id).delete_all
  OrderProjectIssue.unscoped.where(company_id: company.id).delete_all
  OrderProjectTask.unscoped.where(company_id: company.id).delete_all

  OrderHistory.where(order_id: Order.unscoped.where(company_id: company.id).select(:id)).delete_all
  OrderItem.where(order_id: Order.unscoped.where(company_id: company.id).select(:id)).delete_all
  Order.unscoped.where(company_id: company.id).delete_all

  QuotationHistory.where(quotation_id: Quotation.unscoped.where(company_id: company.id).select(:id)).delete_all
  QuotationItem.where(quotation_id: Quotation.unscoped.where(company_id: company.id).select(:id)).delete_all
  Quotation.unscoped.where(company_id: company.id).delete_all

  InvoiceHistory.where(invoice_id: Invoice.unscoped.where(company_id: company.id).select(:id)).delete_all
  InvoiceItem.where(invoice_id: Invoice.unscoped.where(company_id: company.id).select(:id)).delete_all
  Invoice.unscoped.where(company_id: company.id).delete_all

  DeliveryNoteHistory.where(delivery_note_id: DeliveryNote.unscoped.where(company_id: company.id).select(:id)).delete_all
  DeliveryNoteItem.where(delivery_note_id: DeliveryNote.unscoped.where(company_id: company.id).select(:id)).delete_all
  DeliveryNote.unscoped.where(company_id: company.id).delete_all

  ReceiptHistory.where(receipt_id: Receipt.unscoped.where(company_id: company.id).select(:id)).delete_all
  ReceiptItem.where(receipt_id: Receipt.unscoped.where(company_id: company.id).select(:id)).delete_all
  Receipt.unscoped.where(company_id: company.id).delete_all

  Product.unscoped.where(company_id: company.id).delete_all
  Customer.unscoped.where(company_id: company.id).delete_all
  OrderStatus.unscoped.where(company_id: company.id).delete_all

  statuses = {
    new: company.order_statuses.create!(name: "新規", code: "new", color: "#0d6efd", display_order: 1, is_active: true),
    progress: company.order_statuses.create!(name: "進行中", code: "in_progress", color: "#f59e0b", display_order: 2, is_active: true),
    review: company.order_statuses.create!(name: "確認中", code: "review", color: "#6366f1", display_order: 3, is_active: true),
    completed: company.order_statuses.create!(name: "完了", code: "completed", color: "#16a34a", display_order: 4, is_active: true),
    canceled: company.order_statuses.create!(name: "キャンセル", code: "canceled", color: "#6c757d", display_order: 5, is_active: true)
  }

  customers = [
    ["C0001", "ソルプルン", "株式会社ソルプルン", "IT・ソフトウェア", "active"],
    ["C0002", "アオバ建設", "アオバ建設株式会社", "建設", "active"],
    ["C0003", "ミナト商事", "ミナト商事株式会社", "卸売", "prospect"],
    ["C0004", "北都食品", "北都食品株式会社", "食品", "active"],
    ["C0005", "東洋物流", "東洋物流株式会社", "物流", "active"]
  ].map.with_index(1) do |(code, name, company_name, industry, status), index|
    company.customers.create!(
      code: code,
      name: name,
      company_name: company_name,
      industry: industry,
      status: status,
      representative_name: "担当 太郎#{index}",
      phone: "03123456#{format('%02d', index)}",
      email: "customer#{index}@example.com",
      invoice_email: "billing#{index}@example.com",
      address: "東京都千代田区サンプル#{index}-1-1",
      payment_term: "月末締め翌月末払い"
    )
  end

  products = [
    ["P0001", "業務設計支援", 120_000],
    ["P0002", "画面設計", 90_000],
    ["P0003", "Rails実装", 180_000],
    ["P0004", "Stripe連携", 150_000],
    ["P0005", "運用サポート", 80_000]
  ].map do |code, name, price|
    company.products.create!(code: code, name: name, unit_price: price, tax_rate: 1, description: "#{name}のサンプル商品")
  end

  samples = [
    {
      customer: customers[0],
      status: statuses[:new],
      name: "Stripe本番URLテスト",
      summary: "Heroku本番URL上でStripe Checkout、Webhook、決済履歴保存までを確認するためのテスト案件です。",
      amount_index: 3,
      quantity: 1,
      payment_status: :paid
    },
    {
      customer: customers[1],
      status: statuses[:progress],
      name: "案件管理UI整理",
      summary: "案件一覧、案件管理、文書管理の導線を整理し、日常操作を軽くする改善案件です。",
      amount_index: 2,
      quantity: 2,
      payment_status: :pending
    },
    {
      customer: customers[2],
      status: statuses[:review],
      name: "請求書テンプレート調整",
      summary: "見積書から請求書、領収書までの表示項目と印刷レイアウトを確認する案件です。",
      amount_index: 1,
      quantity: 1,
      payment_status: :pending
    },
    {
      customer: customers[3],
      status: statuses[:completed],
      name: "納品フロー検証",
      summary: "納品書作成から入金済み領収書の発行まで、文書管理の一連の流れを確認します。",
      amount_index: 4,
      quantity: 3,
      payment_status: :paid
    },
    {
      customer: customers[4],
      status: statuses[:new],
      name: "AIガント下書き検証",
      summary: "案件概要から工程、タスク、課題、アサインを展開するためのサンプル案件です。",
      amount_index: 0,
      quantity: 2,
      payment_status: :pending
    }
  ]

  samples.each_with_index do |sample, index|
    order_date = Date.current - (index * 4)
    product = products[sample[:amount_index]]
    amount = product.unit_price * sample[:quantity]
    order = company.orders.create!(
      customer: sample[:customer],
      order_status: sample[:status],
      order_date: order_date,
      staff_name: admin.display_name,
      project_name: sample[:name],
      project_summary: sample[:summary],
      delivery_address: sample[:customer].address,
      delivery_date: order_date + 30,
      billing_date: order_date + 20,
      payment_due_date: order_date + 45,
      payment_method: :bank_transfer,
      notes: "ASP検証用サンプル#{index + 1}",
      order_items_attributes: [
        {
          product_id: product.id,
          quantity: sample[:quantity],
          unit_price: product.unit_price,
          amount: amount
        }
      ]
    )

    PaymentRecord.create!(
      company: company,
      order: order,
      status: sample[:payment_status],
      amount: amount,
      currency: "jpy",
      payment_method_type: sample[:payment_status] == :paid ? "card" : "bank_transfer",
      paid_at: sample[:payment_status] == :paid ? Time.current - index.days : nil,
      stripe_checkout_session_id: sample[:payment_status] == :paid ? "cs_demo_#{order.id}" : nil,
      stripe_payment_intent_id: sample[:payment_status] == :paid ? "pi_demo_#{order.id}" : nil
    )

    phase = OrderProjectTask.create!(
      company: company,
      order: order,
      title: "要件整理",
      description: "目的、対象範囲、利用シーンを整理",
      status: index.even? ? :in_progress : :not_started,
      priority: :normal,
      start_date: order_date,
      due_date: order_date + 7,
      position: 1
    )
    OrderProjectTask.create!(
      company: company,
      order: order,
      parent: phase,
      assignee: admin,
      title: "ヒアリング項目作成",
      description: "画面と業務フロー確認用の質問を準備",
      status: index.zero? ? :done : :not_started,
      priority: :normal,
      start_date: order_date,
      due_date: order_date + 3,
      position: 2
    )
    OrderProjectTask.create!(
      company: company,
      order: order,
      parent: phase,
      assignee: admin,
      title: "初期案レビュー",
      description: "作成した管理方針と文書導線を確認",
      status: :not_started,
      priority: index == 0 ? :high : :normal,
      start_date: order_date + 4,
      due_date: order_date + 7,
      position: 3
    )
    OrderProjectIssue.create!(
      company: company,
      order: order,
      assignee: admin,
      title: "確認事項の洗い出し",
      description: "運用開始前に権限、決済、文書番号を確認",
      status: index.even? ? :open : :resolved,
      priority: index.zero? ? :high : :normal,
      due_date: order_date + 10
    )
    OrderAssignment.create!(
      company: company,
      order: order,
      user: admin,
      role: index.zero? ? :owner : :manager,
      note: "サンプル担当"
    )

    doc_attrs = {
      customer_name: sample[:customer].name,
      customer_address: sample[:customer].address,
      subject: sample[:name],
      staff_name: admin.display_name,
      notes: "案件番号: #{order.display_order_number}",
      status: index.even? ? :sent : :pending
    }
    item_attrs = {
      product_code: product.code,
      product_name: product.name,
      unit_price: product.unit_price,
      quantity: sample[:quantity],
      amount: amount,
      tax_rate: 1
    }

    company.quotations.create!(
      doc_attrs.merge(quotation_date: order_date, valid_until: order_date + 30, quotation_items_attributes: [item_attrs])
    )
    company.invoices.create!(
      doc_attrs.merge(
        invoice_date: order_date + 5,
        transaction_date: order_date,
        payment_due_date: order_date + 45,
        payment_method: "銀行振込",
        invoice_items_attributes: [item_attrs]
      )
    )
    company.delivery_notes.create!(
      doc_attrs.merge(
        delivery_date: order_date + 20,
        transaction_date: order_date + 20,
        valid_until: order_date + 30,
        delivery_note_items_attributes: [item_attrs]
      )
    )
    company.receipts.create!(
      doc_attrs.merge(issue_date: order_date + 25, valid_until: order_date + 30, status: sample[:payment_status] == :paid ? :paid : :pending, receipt_items_attributes: [item_attrs])
    )
  end
end

puts "ASP demo data reset for #{company.name}:"
puts "orders=#{Order.unscoped.where(company_id: company.id).count}"
puts "customers=#{Customer.unscoped.where(company_id: company.id).count}"
puts "products=#{Product.unscoped.where(company_id: company.id).count}"
puts "quotations=#{Quotation.unscoped.where(company_id: company.id).count}"
puts "invoices=#{Invoice.unscoped.where(company_id: company.id).count}"
puts "delivery_notes=#{DeliveryNote.unscoped.where(company_id: company.id).count}"
puts "receipts=#{Receipt.unscoped.where(company_id: company.id).count}"
puts "payment_records=#{PaymentRecord.unscoped.where(company_id: company.id).count}"
