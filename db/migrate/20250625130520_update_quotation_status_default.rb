class UpdateQuotationStatusDefault < ActiveRecord::Migration[8.0]
  def up
    # 既存のdraftステータスをpreparationに変更
    Quotation.where(status: 'draft').update_all(status: 'preparation')
    
    # デフォルト値を変更
    change_column_default :quotations, :status, 'preparation'
  end

  def down
    # 既存のpreparationステータスをdraftに戻す
    Quotation.where(status: 'preparation').update_all(status: 'draft')
    
    # デフォルト値を元に戻す
    change_column_default :quotations, :status, 'draft'
  end
end
