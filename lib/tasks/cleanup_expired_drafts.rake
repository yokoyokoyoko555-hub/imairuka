namespace :drafts do
  desc "期限切れの一時保存データを削除"
  task cleanup_expired: :environment do
    # 案件の一時保存データ
    expired_order_count = Order.expired_drafts.count
    Order.cleanup_expired_drafts
    
    # 商品の一時保存データ
    expired_product_count = Product.expired_drafts.count
    Product.expired_drafts.destroy_all
    
    # 顧客の一時保存データ
    expired_customer_count = Customer.expired_drafts.count
    Customer.expired_drafts.destroy_all
    
    # 見積書の一時保存データ
    expired_quotation_count = Quotation.expired_drafts.count
    Quotation.expired_drafts.destroy_all
    
    puts "期限切れの一時保存データを削除しました:"
    puts "  案件: #{expired_order_count} 件"
    puts "  商品: #{expired_product_count} 件"
    puts "  顧客: #{expired_customer_count} 件"
    puts "  見積書: #{expired_quotation_count} 件"
  end

  desc "全ての一時保存データを削除（開発用）"
  task cleanup_all: :environment do
    # 案件の一時保存データ
    all_order_count = Order.drafts.count
    Order.drafts.destroy_all
    
    # 商品の一時保存データ
    all_product_count = Product.drafts.count
    Product.drafts.destroy_all
    
    # 顧客の一時保存データ
    all_customer_count = Customer.drafts.count
    Customer.drafts.destroy_all
    
    # 見積書の一時保存データ
    all_quotation_count = Quotation.drafts.count
    Quotation.drafts.destroy_all
    
    puts "全ての一時保存データを削除しました:"
    puts "  案件: #{all_order_count} 件"
    puts "  商品: #{all_product_count} 件"
    puts "  顧客: #{all_customer_count} 件"
    puts "  見積書: #{all_quotation_count} 件"
  end
end

namespace :cleanup do
  desc "期限切れの一時保存データを削除"
  task expired_drafts: :environment do
    puts "期限切れの一時保存データを削除中..."
    
    # 商品の一時保存データ削除
    expired_products = Product.expired_drafts
    if expired_products.exists?
      expired_products.destroy_all
      puts "商品の一時保存データ #{expired_products.count}件 を削除しました"
    end
    
    # 案件の一時保存データ削除
    expired_projects = Order.expired_drafts
    if expired_projects.exists?
      expired_projects.destroy_all
      puts "案件の一時保存データ #{expired_projects.count}件 を削除しました"
    end
    
    # 顧客の一時保存データ削除
    expired_customers = Customer.expired_drafts
    if expired_customers.exists?
      expired_customers.destroy_all
      puts "顧客の一時保存データ #{expired_customers.count}件 を削除しました"
    end
    
    # 見積書の一時保存データ削除
    expired_quotations = Quotation.expired_drafts
    if expired_quotations.exists?
      expired_quotations.destroy_all
      puts "見積書の一時保存データ #{expired_quotations.count}件 を削除しました"
    end
    
    puts "期限切れの一時保存データ削除が完了しました"
  end
end 