class UpdateProductsCodeIndex < ActiveRecord::Migration[8.0]
  def change
    # 既存のユニークインデックスを削除
    remove_index :products, :code, name: "index_products_on_code"
    
    # discarded_atを含む複合ユニークインデックスを追加
    add_index :products, [:code, :discarded_at], unique: true, name: "index_products_on_code_and_discarded_at"
  end
end
