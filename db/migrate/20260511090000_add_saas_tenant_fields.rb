class AddSaasTenantFields < ActiveRecord::Migration[8.0]
  class MigrationCompany < ActiveRecord::Base
    self.table_name = "companies"
  end

  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  TENANT_TABLES = %i[
    customers
    products
    order_statuses
    orders
    quotations
    invoices
    receipts
    delivery_notes
  ].freeze

  def up
    add_company_contract_fields
    add_user_account_fields
    add_company_references
    ensure_default_company
    backfill_company_ids
    tighten_company_references
    replace_global_unique_indexes
  end

  def down
    restore_global_unique_indexes

    TENANT_TABLES.each do |table|
      remove_reference table, :company, foreign_key: true if column_exists?(table, :company_id)
    end

    remove_reference :payment_records, :company, foreign_key: true if column_exists?(:payment_records, :company_id)

    remove_column :users, :company_id if column_exists?(:users, :company_id)
    remove_column :users, :name if column_exists?(:users, :name)
    remove_column :users, :role if column_exists?(:users, :role)
    remove_column :users, :active if column_exists?(:users, :active)
    remove_column :users, :last_login_at if column_exists?(:users, :last_login_at)

    %i[
      tenant_slug
      contract_status
      plan_name
      trial_ends_at
      suspended_at
      stripe_customer_id
      stripe_subscription_id
      stripe_subscription_status
      stripe_current_period_end
    ].each do |column|
      remove_column :companies, column if column_exists?(:companies, column)
    end
  end

  private

  def add_company_contract_fields
    add_column :companies, :tenant_slug, :string unless column_exists?(:companies, :tenant_slug)
    add_column :companies, :contract_status, :string, null: false, default: "trialing" unless column_exists?(:companies, :contract_status)
    add_column :companies, :plan_name, :string, null: false, default: "standard" unless column_exists?(:companies, :plan_name)
    add_column :companies, :trial_ends_at, :datetime unless column_exists?(:companies, :trial_ends_at)
    add_column :companies, :suspended_at, :datetime unless column_exists?(:companies, :suspended_at)
    add_column :companies, :stripe_customer_id, :string unless column_exists?(:companies, :stripe_customer_id)
    add_column :companies, :stripe_subscription_id, :string unless column_exists?(:companies, :stripe_subscription_id)
    add_column :companies, :stripe_subscription_status, :string unless column_exists?(:companies, :stripe_subscription_status)
    add_column :companies, :stripe_current_period_end, :datetime unless column_exists?(:companies, :stripe_current_period_end)

    add_index :companies, :tenant_slug, unique: true unless index_exists?(:companies, :tenant_slug)
    add_index :companies, :stripe_customer_id unless index_exists?(:companies, :stripe_customer_id)
    add_index :companies, :stripe_subscription_id unless index_exists?(:companies, :stripe_subscription_id)
  end

  def add_user_account_fields
    add_reference :users, :company, foreign_key: true unless column_exists?(:users, :company_id)
    add_column :users, :name, :string unless column_exists?(:users, :name)
    add_column :users, :role, :string, null: false, default: "owner" unless column_exists?(:users, :role)
    add_column :users, :active, :boolean, null: false, default: true unless column_exists?(:users, :active)
    add_column :users, :last_login_at, :datetime unless column_exists?(:users, :last_login_at)
    add_index :users, [:company_id, :role] unless index_exists?(:users, [:company_id, :role])
  end

  def add_company_references
    TENANT_TABLES.each do |table|
      add_reference table, :company, foreign_key: true unless column_exists?(table, :company_id)
    end

    add_reference :payment_records, :company, foreign_key: true unless column_exists?(:payment_records, :company_id)
  end

  def ensure_default_company
    MigrationCompany.reset_column_information
    company = MigrationCompany.first
    return company if company

    MigrationCompany.create!(
      name: "Imairuka Default Company",
      invoice_number: "T0000000000000",
      postal_code: "0000000",
      address: "Default Address",
      phone: "0000000000",
      email: "admin@example.com",
      representative: "Owner",
      business_type: "Service",
      tenant_slug: "default",
      contract_status: "active",
      plan_name: "standard"
    )
  end

  def backfill_company_ids
    company = ensure_default_company
    company_id = company.id

    execute("UPDATE companies SET tenant_slug = COALESCE(NULLIF(tenant_slug, ''), 'company-' || id::text)")
    execute("UPDATE companies SET contract_status = 'active' WHERE contract_status IS NULL OR contract_status = ''")
    execute("UPDATE companies SET plan_name = 'standard' WHERE plan_name IS NULL OR plan_name = ''")

    TENANT_TABLES.each do |table|
      execute("UPDATE #{table} SET company_id = #{company_id} WHERE company_id IS NULL")
    end

    execute("UPDATE payment_records SET company_id = #{company_id} WHERE company_id IS NULL") if table_exists?(:payment_records) && column_exists?(:payment_records, :company_id)
    execute("UPDATE users SET company_id = #{company_id} WHERE company_id IS NULL")
    execute("UPDATE users SET role = 'owner' WHERE role IS NULL OR role = ''")
    execute("UPDATE users SET role = 'platform_admin' WHERE email = 'admin@example.com'")
    execute("UPDATE users SET active = TRUE WHERE active IS NULL")
  end

  def tighten_company_references
    change_column_null :users, :company_id, false

    TENANT_TABLES.each do |table|
      change_column_null table, :company_id, false
    end
  end

  def replace_global_unique_indexes
    remove_index :customers, name: "index_customers_on_code_and_discarded_at" if index_name_exists?(:customers, "index_customers_on_code_and_discarded_at")
    add_index :customers, [:company_id, :code, :discarded_at], unique: true, name: "index_customers_on_company_code_discarded_at" unless index_exists?(:customers, [:company_id, :code, :discarded_at], name: "index_customers_on_company_code_discarded_at")

    remove_index :products, name: "index_products_on_code_and_discarded_at" if index_name_exists?(:products, "index_products_on_code_and_discarded_at")
    add_index :products, [:company_id, :code, :discarded_at], unique: true, name: "index_products_on_company_code_discarded_at" unless index_exists?(:products, [:company_id, :code, :discarded_at], name: "index_products_on_company_code_discarded_at")

    remove_index :order_statuses, name: "index_order_statuses_on_code" if index_name_exists?(:order_statuses, "index_order_statuses_on_code")
    add_index :order_statuses, [:company_id, :code], unique: true, name: "index_order_statuses_on_company_code" unless index_exists?(:order_statuses, [:company_id, :code], name: "index_order_statuses_on_company_code")

    replace_number_index(:orders, :order_number, "index_orders_on_order_number", "index_orders_on_company_order_number")
    replace_number_index(:quotations, :quotation_number, "index_quotations_on_quotation_number", "index_quotations_on_company_quotation_number")
    replace_number_index(:invoices, :invoice_number, "index_invoices_on_invoice_number", "index_invoices_on_company_invoice_number")
    replace_number_index(:receipts, :receipt_number, "index_receipts_on_receipt_number", "index_receipts_on_company_receipt_number")
    replace_number_index(:delivery_notes, :delivery_number, "index_delivery_notes_on_delivery_number", "index_delivery_notes_on_company_delivery_number")
  end

  def replace_number_index(table, column, old_name, new_name)
    remove_index table, name: old_name if index_name_exists?(table, old_name)
    add_index table, [:company_id, column], unique: true, where: "(discarded_at IS NULL)", name: new_name unless index_exists?(table, [:company_id, column], name: new_name)
  end

  def restore_global_unique_indexes
    remove_index :customers, name: "index_customers_on_company_code_discarded_at" if index_name_exists?(:customers, "index_customers_on_company_code_discarded_at")
    add_index :customers, [:code, :discarded_at], unique: true, name: "index_customers_on_code_and_discarded_at" unless index_exists?(:customers, [:code, :discarded_at], name: "index_customers_on_code_and_discarded_at")

    remove_index :products, name: "index_products_on_company_code_discarded_at" if index_name_exists?(:products, "index_products_on_company_code_discarded_at")
    add_index :products, [:code, :discarded_at], unique: true, name: "index_products_on_code_and_discarded_at" unless index_exists?(:products, [:code, :discarded_at], name: "index_products_on_code_and_discarded_at")

    remove_index :order_statuses, name: "index_order_statuses_on_company_code" if index_name_exists?(:order_statuses, "index_order_statuses_on_company_code")
    add_index :order_statuses, :code, unique: true, name: "index_order_statuses_on_code" unless index_exists?(:order_statuses, :code, name: "index_order_statuses_on_code")

    restore_number_index(:orders, :order_number, "index_orders_on_company_order_number", "index_orders_on_order_number")
    restore_number_index(:quotations, :quotation_number, "index_quotations_on_company_quotation_number", "index_quotations_on_quotation_number")
    restore_number_index(:invoices, :invoice_number, "index_invoices_on_company_invoice_number", "index_invoices_on_invoice_number")
    restore_number_index(:receipts, :receipt_number, "index_receipts_on_company_receipt_number", "index_receipts_on_receipt_number")
    restore_number_index(:delivery_notes, :delivery_number, "index_delivery_notes_on_company_delivery_number", "index_delivery_notes_on_delivery_number")
  end

  def restore_number_index(table, column, old_name, new_name)
    remove_index table, name: old_name if index_name_exists?(table, old_name)
    add_index table, column, unique: true, where: "(discarded_at IS NULL)", name: new_name unless index_exists?(table, column, name: new_name)
  end
end
