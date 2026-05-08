class DashboardController < ApplicationController
  def index
    # 今月の売上（請求書から計算）
    current_month = Date.current.beginning_of_month
    @monthly_sales = Invoice.where(invoice_date: current_month..current_month.end_of_month)
                           .sum(:total_amount)
    
    # 前月の売上
    last_month = current_month - 1.month
    last_month_sales = Invoice.where(invoice_date: last_month..last_month.end_of_month)
                             .sum(:total_amount)
    
    # 前月比の計算
    if last_month_sales > 0
      @monthly_sales_change = ((@monthly_sales - last_month_sales) / last_month_sales.to_f * 100).round(1)
    else
      @monthly_sales_change = @monthly_sales > 0 ? 100.0 : 0.0
    end

    # 年間累計売上
    current_year = Date.current.beginning_of_year
    @yearly_sales = Invoice.where(invoice_date: current_year..current_year.end_of_year)
                          .sum(:total_amount)

    # 案件統計
    @new_orders = Order.where(order_date: current_month..current_month.end_of_month).count
    @processing_orders = Order.joins(:order_status)
                             .where.not(order_statuses: { code: ['completed', 'cancelled'] })
                             .count
    @completed_orders = Order.joins(:order_status)
                            .where(order_statuses: { code: 'completed' })
                            .count

    # 在庫アラート（在庫数が閾値以下の商品）
    @low_stock_products = Product.where('stock_quantity <= stock_threshold')
                                .where.not(stock_quantity: nil)
                                .where.not(stock_threshold: nil)
                                .limit(10)

    # 最近の案件
    @recent_orders = Order.includes(:customer, :order_status)
                         .order(created_at: :desc)
                         .limit(5)

    # 最近の請求書
    @recent_invoices = Invoice.order(created_at: :desc).limit(5)

    # 顧客統計
    @total_customers = Customer.where(is_active: true).count
    @new_customers_this_month = Customer.where(is_active: true)
                                       .where(created_at: current_month..current_month.end_of_month)
                                       .count

    # 売上推移データ（過去6ヶ月）
    @sales_trend = (5.downto(0)).map do |i|
      month_start = current_month - i.months
      month_end = month_start.end_of_month
      sales = Invoice.where(invoice_date: month_start..month_end).sum(:total_amount)
      {
        month: month_start.strftime('%Y年%m月'),
        sales: sales
      }
    end

    # 業種別顧客数
    @customers_by_industry = Customer.where(is_active: true)
                                    .group(:industry)
                                    .count
                                    .sort_by { |_, count| -count }
                                    .first(5)

    # 支払い状況
    @pending_invoices = Invoice.where(status: 'pending').count
    @overdue_invoices = Invoice.where('payment_due_date < ? AND status = ?', Date.current, 'pending').count
  end
end 