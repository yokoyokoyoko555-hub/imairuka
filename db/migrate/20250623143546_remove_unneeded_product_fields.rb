class RemoveUnneededProductFields < ActiveRecord::Migration[8.0]
  def change
    remove_column :products, :cost_price, :integer
    remove_column :products, :stock_quantity, :integer
    remove_column :products, :stock_threshold, :integer
    remove_column :products, :category, :string
    remove_column :products, :payment_terms, :string
    remove_column :products, :payment_method, :string
    remove_column :products, :invoice_email, :string
    remove_column :products, :image_url, :string
    remove_column :products, :supplier_name, :string
    remove_column :products, :supplier_contact, :string
    remove_column :products, :supplier_phone, :string
    remove_column :products, :supplier_email, :string
  end
end
