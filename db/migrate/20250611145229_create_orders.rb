class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :customers do |t|
      t.string :name, null: false, comment: '顧客名'
      t.string :code, null: false, comment: '顧客コード'
      t.string :address, comment: '住所'
      t.string :phone, comment: '電話番号'
      t.string :email, comment: 'メールアドレス'
      t.text :notes, comment: '備考'
      t.boolean :is_active, default: true, null: false, comment: '有効フラグ'

      t.timestamps
    end
    add_index :customers, :code, unique: true
    add_index :customers, :name

    create_table :products do |t|
      t.string :code, null: false, comment: '商品コード'
      t.string :name, null: false, comment: '商品名'
      t.integer :unit_price, null: false, comment: '単価'
      t.text :description, comment: '商品説明'
      t.boolean :is_active, default: true, null: false, comment: '有効フラグ'

      t.timestamps
    end
    add_index :products, :code, unique: true
    add_index :products, :name

    create_table :orders do |t|
      t.string :order_number, null: false, comment: '案件番号'
      t.references :customer, null: false, foreign_key: true, comment: '顧客ID'
      t.date :order_date, null: false, comment: '注文日'
      t.string :staff_name, null: false, comment: '担当者名'
      t.integer :total_amount, null: false, default: 0, comment: '合計金額'
      t.string :status, null: false, default: 'received', comment: 'ステータス'
      t.text :notes, comment: '備考'
      t.string :delivery_address, comment: '配送先'
      t.date :delivery_date, comment: '納品日'
      t.string :delivery_staff, comment: '配送担当者'
      t.string :billing_address, comment: '請求先'
      t.date :payment_due_date, comment: '支払期限'
      t.string :payment_method, comment: '支払方法'
      t.date :payment_date, comment: '入金日'

      t.timestamps
    end
    add_index :orders, :order_number, unique: true
    add_index :orders, :order_date
    add_index :orders, :status

    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true, comment: '案件ID'
      t.references :product, null: false, foreign_key: true, comment: '商品ID'
      t.integer :quantity, null: false, comment: '数量'
      t.integer :unit_price, null: false, comment: '単価'
      t.integer :amount, null: false, comment: '金額'

      t.timestamps
    end
    add_index :order_items, [:order_id, :product_id]
  end
end
