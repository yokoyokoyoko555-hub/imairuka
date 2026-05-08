class AddOrderStatusIdToOrders < ActiveRecord::Migration[7.1]
  def up
    # 一時的にnull制約を外してorder_status_idを追加
    add_reference :orders, :order_status, null: true, foreign_key: true

    # 既存のstatusデータをorder_statusesテーブルに移行
    # 1. 既存のstatus値を取得
    statuses = Order.distinct.pluck(:status).compact

    # 2. 各statusに対してorder_statusesレコードを作成
    statuses.each do |status|
      # ステータスコードは既存のstatus値をそのまま使用
      code = status.underscore
      # ステータス名は日本語表示用に変換
      name = case status
             when 'received' then '受付済'
             when 'ordered' then '発注済'
             when 'delivered' then '納品済'
             when 'billed' then '請求済'
             when 'paid' then '入金済'
             else status
             end

      # 表示順は既存のレコード数+1
      display_order = OrderStatus.count + 1

      # order_statusesレコードを作成
      order_status = OrderStatus.create!(
        name: name,
        code: code,
        display_order: display_order,
        is_active: true
      )

      # 該当するstatusを持つordersのorder_status_idを更新
      Order.where(status: status).update_all(order_status_id: order_status.id)
    end

    # もし、既存のstatusに含まれていないステータスがあれば、それも追加
    missing_statuses = {
      'delivered' => '納品済',
      'billed' => '請求済',
      'paid' => '入金済'
    }

    missing_statuses.each do |code, name|
      next if OrderStatus.exists?(code: code)

      display_order = OrderStatus.count + 1
      OrderStatus.create!(
        name: name,
        code: code,
        display_order: display_order,
        is_active: true
      )
    end

    # order_status_idにnull制約を追加
    change_column_null :orders, :order_status_id, false

    # statusカラムを削除
    remove_column :orders, :status
  end

  def down
    # statusカラムを追加（元の型で）
    add_column :orders, :status, :string

    # order_statusesのデータをordersのstatusに戻す
    Order.find_each do |order|
      if order.order_status
        order.update_column(:status, order.order_status.code)
      end
    end

    # order_status_idを削除
    remove_reference :orders, :order_status
  end
end
