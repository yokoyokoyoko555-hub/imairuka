class RemoveExpiresAtFromAllModels < ActiveRecord::Migration[8.0]
  def up
    # 商品からexpires_atを削除
    if column_exists?(:products, :expires_at)
      remove_column :products, :expires_at, :datetime
      remove_index :products, :expires_at if index_exists?(:products, :expires_at)
    end

    # 顧客からexpires_atを削除
    if column_exists?(:customers, :expires_at)
      remove_column :customers, :expires_at, :datetime
      remove_index :customers, :expires_at if index_exists?(:customers, :expires_at)
    end

    # 見積書からexpires_atを削除
    if column_exists?(:quotations, :expires_at)
      remove_column :quotations, :expires_at, :datetime
      remove_index :quotations, :expires_at if index_exists?(:quotations, :expires_at)
    end

    # 納品書からexpires_atを削除
    if column_exists?(:delivery_notes, :expires_at)
      remove_column :delivery_notes, :expires_at, :datetime
      remove_index :delivery_notes, :expires_at if index_exists?(:delivery_notes, :expires_at)
    end

    # 請求書からexpires_atを削除
    if column_exists?(:invoices, :expires_at)
      remove_column :invoices, :expires_at, :datetime
      remove_index :invoices, :expires_at if index_exists?(:invoices, :expires_at)
    end

    # 領収書からexpires_atを削除
    if column_exists?(:receipts, :expires_at)
      remove_column :receipts, :expires_at, :datetime
      remove_index :receipts, :expires_at if index_exists?(:receipts, :expires_at)
    end
  end

  def down
    # 商品にexpires_atを追加
    unless column_exists?(:products, :expires_at)
      add_column :products, :expires_at, :datetime
      add_index :products, :expires_at
    end

    # 顧客にexpires_atを追加
    unless column_exists?(:customers, :expires_at)
      add_column :customers, :expires_at, :datetime
      add_index :customers, :expires_at
    end

    # 見積書にexpires_atを追加
    unless column_exists?(:quotations, :expires_at)
      add_column :quotations, :expires_at, :datetime
      add_index :quotations, :expires_at
    end

    # 納品書にexpires_atを追加
    unless column_exists?(:delivery_notes, :expires_at)
      add_column :delivery_notes, :expires_at, :datetime
      add_index :delivery_notes, :expires_at
    end

    # 請求書にexpires_atを追加
    unless column_exists?(:invoices, :expires_at)
      add_column :invoices, :expires_at, :datetime
      add_index :invoices, :expires_at
    end

    # 領収書にexpires_atを追加
    unless column_exists?(:receipts, :expires_at)
      add_column :receipts, :expires_at, :datetime
      add_index :receipts, :expires_at
    end
  end
end
