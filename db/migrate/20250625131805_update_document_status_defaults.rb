class UpdateDocumentStatusDefaults < ActiveRecord::Migration[8.0]
  def up
    # 納品書の変更
    # 既存のdraftステータスをpreparationに変更
    DeliveryNote.where(status: 'draft').update_all(status: 'preparation')
    # デフォルト値を変更
    change_column_default :delivery_notes, :status, 'preparation'
    # draftとexpires_atカラムを追加
    add_column :delivery_notes, :draft, :boolean, default: false, null: false
    add_column :delivery_notes, :expires_at, :datetime
    add_index :delivery_notes, :draft
    add_index :delivery_notes, :expires_at

    # 請求書の変更
    # 既存のdraftステータスをpreparationに変更
    Invoice.where(status: 'draft').update_all(status: 'preparation')
    # デフォルト値を変更
    change_column_default :invoices, :status, 'preparation'
    # draftとexpires_atカラムを追加
    add_column :invoices, :draft, :boolean, default: false, null: false
    add_column :invoices, :expires_at, :datetime
    add_index :invoices, :draft
    add_index :invoices, :expires_at

    # 領収書の変更
    # 既存のdraftステータスをpreparationに変更
    Receipt.where(status: 'draft').update_all(status: 'preparation')
    # デフォルト値を変更
    change_column_default :receipts, :status, 'preparation'
    # draftとexpires_atカラムを追加
    add_column :receipts, :draft, :boolean, default: false, null: false
    add_column :receipts, :expires_at, :datetime
    add_index :receipts, :draft
    add_index :receipts, :expires_at
  end

  def down
    # 納品書の変更を元に戻す
    DeliveryNote.where(status: 'preparation').update_all(status: 'draft')
    change_column_default :delivery_notes, :status, 'draft'
    remove_column :delivery_notes, :draft
    remove_column :delivery_notes, :expires_at

    # 請求書の変更を元に戻す
    Invoice.where(status: 'preparation').update_all(status: 'draft')
    change_column_default :invoices, :status, 'draft'
    remove_column :invoices, :draft
    remove_column :invoices, :expires_at

    # 領収書の変更を元に戻す
    Receipt.where(status: 'preparation').update_all(status: 'draft')
    change_column_default :receipts, :status, 'draft'
    remove_column :receipts, :draft
    remove_column :receipts, :expires_at
  end
end
