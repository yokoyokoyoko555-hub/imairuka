class AddFieldsToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :cost_price, :integer
    add_column :products, :stock_quantity, :integer
    add_column :products, :stock_threshold, :integer
    add_column :products, :category, :string
    add_column :products, :payment_terms, :string
    add_column :products, :payment_method, :string
    add_column :products, :invoice_email, :string
    add_column :products, :image_url, :string
    add_column :products, :supplier_name, :string
    add_column :products, :supplier_contact, :string
    add_column :products, :supplier_phone, :string
    add_column :products, :supplier_email, :string
  end
end
