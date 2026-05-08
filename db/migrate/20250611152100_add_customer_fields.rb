class AddCustomerFields < ActiveRecord::Migration[8.0]
  def change
    # 基本情報の追加（既存のカラムは除外）
    add_column :customers, :company_name, :string, null: false, comment: '会社名'
    add_column :customers, :industry, :string, null: false, comment: '業種'
    add_column :customers, :established_date, :date, comment: '設立年月日'
    add_column :customers, :capital, :integer, comment: '資本金'
    add_column :customers, :representative_name, :string, comment: '代表者名'
    add_column :customers, :employee_count, :integer, comment: '従業員数'
    add_column :customers, :business_description, :text, comment: '事業内容'
    add_column :customers, :status, :string, null: false, default: 'prospect', comment: 'ステータス'

    # 請求情報の追加
    add_column :customers, :payment_term, :string, comment: '支払い条件'
    add_column :customers, :payment_method, :string, comment: '支払い方法'
    add_column :customers, :invoice_email, :string, comment: '請求書送付先メールアドレス'

    # インデックスの追加
    add_index :customers, :company_name
    add_index :customers, :industry
    add_index :customers, :status

    # 担当者情報テーブルの作成
    create_table :customer_contacts, comment: '顧客担当者' do |t|
      t.references :customer, null: false, foreign_key: true, comment: '顧客ID'
      t.string :name, null: false, comment: '担当者名'
      t.string :position, comment: '役職'
      t.string :phone_number, comment: '電話番号'
      t.string :email, comment: 'メールアドレス'
      t.boolean :is_active, null: false, default: true, comment: '有効フラグ'

      t.timestamps
    end
    add_index :customer_contacts, [:customer_id, :name]

    # メモテーブルの作成
    create_table :customer_notes, comment: '顧客メモ' do |t|
      t.references :customer, null: false, foreign_key: true, comment: '顧客ID'
      t.text :content, null: false, comment: 'メモ内容'

      t.timestamps
    end

    # 添付ファイルテーブルの作成
    create_table :customer_attachments, comment: '顧客添付ファイル' do |t|
      t.references :customer, null: false, foreign_key: true, comment: '顧客ID'
      t.string :filename, null: false, comment: 'ファイル名'
      t.string :file_type, comment: 'ファイルタイプ'
      t.string :file_path, null: false, comment: 'ファイルパス'

      t.timestamps
    end
    add_index :customer_attachments, [:customer_id, :filename]

    # 既存のnameカラムの値をcompany_nameにコピー
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE customers 
          SET name = company_name 
          WHERE name IS NULL OR name = '';
        SQL
      end
    end
  end
end 