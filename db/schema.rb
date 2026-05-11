# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_05_11_100000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.string "invoice_number"
    t.text "address"
    t.string "phone"
    t.string "email"
    t.string "bank_name"
    t.string "bank_branch"
    t.string "bank_account_type"
    t.string "bank_account_number"
    t.string "bank_account_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "postal_code", comment: "郵便番号"
    t.string "representative", comment: "代表者名"
    t.string "business_type", comment: "業種"
    t.string "stripe_account_id"
    t.boolean "stripe_charges_enabled", default: false, null: false
    t.boolean "stripe_payouts_enabled", default: false, null: false
    t.boolean "stripe_details_submitted", default: false, null: false
    t.datetime "stripe_onboarded_at"
    t.string "tenant_slug"
    t.string "contract_status", default: "trialing", null: false
    t.string "plan_name", default: "standard", null: false
    t.datetime "trial_ends_at"
    t.datetime "suspended_at"
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.string "stripe_subscription_status"
    t.datetime "stripe_current_period_end"
    t.index ["stripe_account_id"], name: "index_companies_on_stripe_account_id", unique: true
    t.index ["stripe_customer_id"], name: "index_companies_on_stripe_customer_id"
    t.index ["stripe_subscription_id"], name: "index_companies_on_stripe_subscription_id"
    t.index ["tenant_slug"], name: "index_companies_on_tenant_slug", unique: true
  end

  create_table "customer_attachments", comment: "顧客添付ファイル", force: :cascade do |t|
    t.bigint "customer_id", null: false, comment: "顧客ID"
    t.string "filename", null: false, comment: "ファイル名"
    t.string "file_type", comment: "ファイルタイプ"
    t.string "file_path", null: false, comment: "ファイルパス"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "filename"], name: "index_customer_attachments_on_customer_id_and_filename"
    t.index ["customer_id"], name: "index_customer_attachments_on_customer_id"
  end

  create_table "customer_contacts", comment: "顧客担当者", force: :cascade do |t|
    t.bigint "customer_id", null: false, comment: "顧客ID"
    t.string "name", null: false, comment: "担当者名"
    t.string "position", comment: "役職"
    t.string "phone_number", comment: "電話番号"
    t.string "email", comment: "メールアドレス"
    t.boolean "is_active", default: true, null: false, comment: "有効フラグ"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "name"], name: "index_customer_contacts_on_customer_id_and_name"
    t.index ["customer_id"], name: "index_customer_contacts_on_customer_id"
  end

  create_table "customer_notes", comment: "顧客メモ", force: :cascade do |t|
    t.bigint "customer_id", null: false, comment: "顧客ID"
    t.text "content", null: false, comment: "メモ内容"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_customer_notes_on_customer_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name", comment: "顧客名"
    t.string "code", null: false, comment: "顧客コード"
    t.string "address", comment: "住所"
    t.string "phone", comment: "電話番号"
    t.string "email", comment: "メールアドレス"
    t.text "notes", comment: "備考"
    t.boolean "is_active", default: true, null: false, comment: "有効フラグ"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name_kana"
    t.string "postal_code"
    t.string "company_name", null: false, comment: "会社名"
    t.string "industry", null: false, comment: "業種"
    t.date "established_date", comment: "設立年月日"
    t.integer "capital", comment: "資本金"
    t.string "representative_name", comment: "代表者名"
    t.integer "employee_count", comment: "従業員数"
    t.text "business_description", comment: "事業内容"
    t.string "status", default: "prospect", null: false, comment: "ステータス"
    t.string "payment_term", comment: "支払い条件"
    t.string "payment_method", comment: "支払い方法"
    t.string "invoice_email", comment: "請求書送付先メールアドレス"
    t.datetime "discarded_at"
    t.boolean "draft", default: false, null: false
    t.bigint "company_id", null: false
    t.index ["company_id", "code", "discarded_at"], name: "index_customers_on_company_code_discarded_at", unique: true
    t.index ["company_id"], name: "index_customers_on_company_id"
    t.index ["company_name"], name: "index_customers_on_company_name"
    t.index ["discarded_at"], name: "index_customers_on_discarded_at"
    t.index ["draft"], name: "index_customers_on_draft"
    t.index ["industry"], name: "index_customers_on_industry"
    t.index ["name"], name: "index_customers_on_name"
    t.index ["status"], name: "index_customers_on_status"
  end

  create_table "delivery_note_histories", force: :cascade do |t|
    t.bigint "delivery_note_id", null: false
    t.string "action"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_note_id"], name: "index_delivery_note_histories_on_delivery_note_id"
  end

  create_table "delivery_note_items", force: :cascade do |t|
    t.bigint "delivery_note_id", null: false
    t.string "product_code"
    t.string "product_name"
    t.integer "unit_price"
    t.integer "quantity"
    t.integer "amount"
    t.integer "tax_rate"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_note_id"], name: "index_delivery_note_items_on_delivery_note_id"
    t.index ["discarded_at"], name: "index_delivery_note_items_on_discarded_at"
  end

  create_table "delivery_notes", force: :cascade do |t|
    t.string "delivery_number"
    t.date "delivery_date"
    t.string "customer_name"
    t.string "staff_name"
    t.string "status", default: "pending"
    t.text "notes"
    t.integer "total_amount"
    t.date "valid_until"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "customer_address"
    t.string "subject"
    t.boolean "draft", default: false, null: false
    t.bigint "company_id", null: false
    t.index ["company_id", "delivery_number"], name: "index_delivery_notes_on_company_delivery_number", unique: true, where: "(discarded_at IS NULL)"
    t.index ["company_id"], name: "index_delivery_notes_on_company_id"
    t.index ["discarded_at"], name: "index_delivery_notes_on_discarded_at"
    t.index ["draft"], name: "index_delivery_notes_on_draft"
  end

  create_table "invoice_histories", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_invoice_histories_on_action"
    t.index ["created_at"], name: "index_invoice_histories_on_created_at"
    t.index ["invoice_id"], name: "index_invoice_histories_on_invoice_id"
  end

  create_table "invoice_items", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.string "product_code", null: false
    t.string "product_name", null: false
    t.integer "unit_price", default: 0, null: false
    t.integer "quantity", default: 1, null: false
    t.integer "tax_rate", default: 1
    t.integer "amount", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_invoice_items_on_discarded_at"
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
    t.index ["product_code"], name: "index_invoice_items_on_product_code"
    t.index ["tax_rate"], name: "index_invoice_items_on_tax_rate"
  end

  create_table "invoices", force: :cascade do |t|
    t.string "invoice_number"
    t.date "invoice_date"
    t.string "customer_name"
    t.text "customer_address"
    t.string "subject"
    t.string "staff_name"
    t.string "status", default: "pending"
    t.text "notes"
    t.integer "total_amount", default: 0
    t.date "payment_due_date"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "payment_method"
    t.boolean "draft", default: false, null: false
    t.bigint "company_id", null: false
    t.index ["company_id", "invoice_number"], name: "index_invoices_on_company_invoice_number", unique: true, where: "(discarded_at IS NULL)"
    t.index ["company_id"], name: "index_invoices_on_company_id"
    t.index ["customer_name"], name: "index_invoices_on_customer_name"
    t.index ["discarded_at"], name: "index_invoices_on_discarded_at"
    t.index ["draft"], name: "index_invoices_on_draft"
    t.index ["invoice_date"], name: "index_invoices_on_invoice_date"
    t.index ["status"], name: "index_invoices_on_status"
  end

  create_table "order_histories", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.string "action", null: false
    t.text "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "staff_name", default: "システム", null: false
    t.index ["action"], name: "index_order_histories_on_action"
    t.index ["created_at"], name: "index_order_histories_on_created_at"
    t.index ["order_id"], name: "index_order_histories_on_order_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false, comment: "案件ID"
    t.bigint "product_id", null: false, comment: "商品ID"
    t.integer "quantity", null: false, comment: "数量"
    t.integer "unit_price", null: false, comment: "単価"
    t.integer "amount", null: false, comment: "金額"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id", "product_id"], name: "index_order_items_on_order_id_and_product_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "order_statuses", force: :cascade do |t|
    t.string "name", null: false, comment: "ステータス名"
    t.string "code", null: false, comment: "ステータスコード"
    t.integer "display_order", default: 0, null: false, comment: "表示順"
    t.string "color", comment: "表示色"
    t.text "description", comment: "説明"
    t.boolean "is_active", default: true, null: false, comment: "有効フラグ"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id", null: false
    t.index ["company_id", "code"], name: "index_order_statuses_on_company_code", unique: true
    t.index ["company_id"], name: "index_order_statuses_on_company_id"
    t.index ["display_order"], name: "index_order_statuses_on_display_order"
    t.index ["is_active"], name: "index_order_statuses_on_is_active"
  end

  create_table "orders", force: :cascade do |t|
    t.string "order_number", comment: "案件番号"
    t.bigint "customer_id", comment: "顧客ID"
    t.date "order_date", null: false, comment: "注文日"
    t.string "staff_name", comment: "担当者名"
    t.integer "total_amount", default: 0, null: false, comment: "合計金額"
    t.text "notes", comment: "備考"
    t.string "delivery_address", comment: "配送先"
    t.date "delivery_date", comment: "納品日"
    t.string "billing_address", comment: "請求先"
    t.date "payment_due_date", comment: "支払期限"
    t.string "payment_method", comment: "支払方法"
    t.date "payment_date", comment: "入金日"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "billing_date"
    t.bigint "order_status_id"
    t.datetime "discarded_at"
    t.boolean "draft", default: false, null: false
    t.bigint "company_id", null: false
    t.index ["company_id", "order_number"], name: "index_orders_on_company_order_number", unique: true, where: "(discarded_at IS NULL)"
    t.index ["company_id"], name: "index_orders_on_company_id"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["discarded_at"], name: "index_orders_on_discarded_at"
    t.index ["draft"], name: "index_orders_on_draft"
    t.index ["order_date"], name: "index_orders_on_order_date"
    t.index ["order_status_id"], name: "index_orders_on_order_status_id"
  end

  create_table "payment_records", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "company_id"
    t.string "stripe_account_id"
    t.string "stripe_checkout_session_id"
    t.string "stripe_payment_intent_id"
    t.string "stripe_charge_id"
    t.string "stripe_event_id"
    t.string "status", default: "pending", null: false
    t.integer "amount", default: 0, null: false
    t.string "currency", default: "jpy", null: false
    t.string "payment_method_type"
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_payment_records_on_company_id"
    t.index ["order_id"], name: "index_payment_records_on_order_id"
    t.index ["paid_at"], name: "index_payment_records_on_paid_at"
    t.index ["status"], name: "index_payment_records_on_status"
    t.index ["stripe_checkout_session_id"], name: "index_payment_records_on_stripe_checkout_session_id", unique: true
    t.index ["stripe_event_id"], name: "index_payment_records_on_stripe_event_id"
    t.index ["stripe_payment_intent_id"], name: "index_payment_records_on_stripe_payment_intent_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "code", null: false, comment: "商品コード"
    t.string "name", null: false, comment: "商品名"
    t.integer "unit_price", comment: "単価"
    t.text "description", comment: "商品説明"
    t.boolean "is_active", default: true, null: false, comment: "有効フラグ"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "notes"
    t.datetime "discarded_at"
    t.integer "tax_rate"
    t.string "supplier_name"
    t.string "supplier_contact"
    t.string "supplier_phone"
    t.string "supplier_email"
    t.integer "cost_price"
    t.integer "stock_quantity"
    t.integer "stock_threshold"
    t.boolean "draft"
    t.bigint "company_id", null: false
    t.index ["company_id", "code", "discarded_at"], name: "index_products_on_company_code_discarded_at", unique: true
    t.index ["company_id"], name: "index_products_on_company_id"
    t.index ["discarded_at"], name: "index_products_on_discarded_at"
    t.index ["name"], name: "index_products_on_name"
  end

  create_table "quotation_histories", force: :cascade do |t|
    t.bigint "quotation_id", null: false
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["created_at"], name: "index_quotation_histories_on_created_at"
    t.index ["discarded_at"], name: "index_quotation_histories_on_discarded_at"
    t.index ["quotation_id"], name: "index_quotation_histories_on_quotation_id"
  end

  create_table "quotation_items", force: :cascade do |t|
    t.bigint "quotation_id", null: false
    t.string "product_code", null: false
    t.string "product_name", null: false
    t.integer "unit_price", default: 0, null: false
    t.integer "quantity", default: 1, null: false
    t.integer "amount", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.integer "tax_rate"
    t.index ["discarded_at"], name: "index_quotation_items_on_discarded_at"
    t.index ["product_code"], name: "index_quotation_items_on_product_code"
    t.index ["quotation_id"], name: "index_quotation_items_on_quotation_id"
  end

  create_table "quotations", force: :cascade do |t|
    t.string "quotation_number"
    t.date "quotation_date"
    t.string "customer_name"
    t.integer "total_amount", default: 0
    t.string "status", default: "pending"
    t.string "staff_name"
    t.date "valid_until"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.text "customer_address"
    t.string "subject"
    t.boolean "draft", default: false, null: false
    t.bigint "company_id", null: false
    t.index ["company_id", "quotation_number"], name: "index_quotations_on_company_quotation_number", unique: true, where: "(discarded_at IS NULL)"
    t.index ["company_id"], name: "index_quotations_on_company_id"
    t.index ["customer_name"], name: "index_quotations_on_customer_name"
    t.index ["discarded_at"], name: "index_quotations_on_discarded_at"
    t.index ["draft"], name: "index_quotations_on_draft"
    t.index ["quotation_date"], name: "index_quotations_on_quotation_date"
    t.index ["status"], name: "index_quotations_on_status"
  end

  create_table "receipt_histories", force: :cascade do |t|
    t.bigint "receipt_id", null: false
    t.string "action"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_receipt_histories_on_discarded_at"
    t.index ["receipt_id"], name: "index_receipt_histories_on_receipt_id"
  end

  create_table "receipt_items", force: :cascade do |t|
    t.bigint "receipt_id", null: false
    t.string "product_code"
    t.string "product_name"
    t.integer "unit_price"
    t.integer "quantity"
    t.integer "amount"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tax_rate"
    t.index ["discarded_at"], name: "index_receipt_items_on_discarded_at"
    t.index ["receipt_id"], name: "index_receipt_items_on_receipt_id"
  end

  create_table "receipts", force: :cascade do |t|
    t.string "receipt_number"
    t.date "issue_date"
    t.string "customer_name"
    t.integer "total_amount"
    t.string "status", default: "pending"
    t.string "staff_name"
    t.date "valid_until"
    t.text "notes"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "customer_address"
    t.string "subject"
    t.boolean "draft", default: false, null: false
    t.bigint "company_id", null: false
    t.index ["company_id", "receipt_number"], name: "index_receipts_on_company_receipt_number", unique: true, where: "(discarded_at IS NULL)"
    t.index ["company_id"], name: "index_receipts_on_company_id"
    t.index ["discarded_at"], name: "index_receipts_on_discarded_at"
    t.index ["draft"], name: "index_receipts_on_draft"
  end

  create_table "user_invitations", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "invited_by_id"
    t.string "email", null: false
    t.string "name"
    t.string "role", default: "member", null: false
    t.string "token_digest", null: false
    t.datetime "accepted_at"
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["accepted_at"], name: "index_user_invitations_on_accepted_at"
    t.index ["company_id", "email"], name: "index_user_invitations_on_company_id_and_email"
    t.index ["company_id"], name: "index_user_invitations_on_company_id"
    t.index ["invited_by_id"], name: "index_user_invitations_on_invited_by_id"
    t.index ["token_digest"], name: "index_user_invitations_on_token_digest", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "remember_digest"
    t.bigint "company_id", null: false
    t.string "name"
    t.string "role", default: "owner", null: false
    t.boolean "active", default: true, null: false
    t.datetime "last_login_at"
    t.index ["company_id", "role"], name: "index_users_on_company_id_and_role"
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "customer_attachments", "customers"
  add_foreign_key "customer_contacts", "customers"
  add_foreign_key "customer_notes", "customers"
  add_foreign_key "customers", "companies"
  add_foreign_key "delivery_note_histories", "delivery_notes"
  add_foreign_key "delivery_note_items", "delivery_notes"
  add_foreign_key "delivery_notes", "companies"
  add_foreign_key "invoice_histories", "invoices"
  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoices", "companies"
  add_foreign_key "order_histories", "orders"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "order_statuses", "companies"
  add_foreign_key "orders", "companies"
  add_foreign_key "orders", "customers"
  add_foreign_key "orders", "order_statuses"
  add_foreign_key "payment_records", "companies"
  add_foreign_key "payment_records", "orders"
  add_foreign_key "products", "companies"
  add_foreign_key "quotation_histories", "quotations"
  add_foreign_key "quotation_items", "quotations"
  add_foreign_key "quotations", "companies"
  add_foreign_key "receipt_histories", "receipts"
  add_foreign_key "receipt_items", "receipts"
  add_foreign_key "receipts", "companies"
  add_foreign_key "user_invitations", "companies"
  add_foreign_key "user_invitations", "users", column: "invited_by_id"
  add_foreign_key "users", "companies"
end
