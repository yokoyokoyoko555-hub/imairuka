class UnifyDocumentTablesRemoveNotNullConstraints < ActiveRecord::Migration[8.0]
  def change
    # 見積書テーブル
    change_column_null :quotations, :quotation_number, true
    change_column_null :quotations, :quotation_date, true
    change_column_null :quotations, :customer_name, true
    change_column_null :quotations, :staff_name, true
    change_column_null :quotations, :status, true
    change_column_null :quotations, :total_amount, true

    # 請求書テーブル
    change_column_null :invoices, :invoice_number, true
    change_column_null :invoices, :invoice_date, true
    change_column_null :invoices, :customer_name, true
    change_column_null :invoices, :staff_name, true
    change_column_null :invoices, :status, true
    change_column_null :invoices, :total_amount, true

    # 納品書テーブル - 既にNULL可なので変更なし
    # change_column_null :delivery_notes, :delivery_number, true
    # change_column_null :delivery_notes, :delivery_date, true
    # change_column_null :delivery_notes, :customer_name, true
    # change_column_null :delivery_notes, :staff_name, true
    # change_column_null :delivery_notes, :status, true
    # change_column_null :delivery_notes, :total_amount, true

    # 領収書テーブル - 既にNULL可なので変更なし
    # change_column_null :receipts, :receipt_number, true
    # change_column_null :receipts, :issue_date, true
    # change_column_null :receipts, :customer_name, true
    # change_column_null :receipts, :staff_name, true
    # change_column_null :receipts, :status, true
    # change_column_null :receipts, :total_amount, true
  end
end
