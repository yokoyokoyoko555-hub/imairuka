class AddVendorInvoiceContracts < ActiveRecord::Migration[8.0]
  def change
    create_table :vendors do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :contact_name
      t.string :email
      t.string :phone
      t.string :postal_code
      t.text :address
      t.string :status, null: false, default: "active"
      t.text :notes

      t.timestamps
    end

    add_index :vendors, :code, unique: true
    add_index :vendors, :status

    add_reference :companies, :vendor, foreign_key: true
    add_column :companies, :sales_channel, :string, null: false, default: "direct"
    add_column :companies, :billing_payer_type, :string, null: false, default: "company"
    add_column :companies, :contract_amount, :integer, null: false, default: 100_000
    add_column :companies, :contract_months, :integer, null: false, default: 24
    add_column :companies, :contract_starts_on, :date
    add_column :companies, :contract_ends_on, :date
    add_column :companies, :billing_status, :string, null: false, default: "unbilled"
    add_column :companies, :internal_invoice_number, :string
    add_column :companies, :invoiced_on, :date
    add_column :companies, :payment_due_on, :date
    add_column :companies, :paid_on, :date
    add_column :companies, :contract_notes, :text

    add_index :companies, :sales_channel
    add_index :companies, :billing_status
    add_index :companies, :internal_invoice_number
  end
end
