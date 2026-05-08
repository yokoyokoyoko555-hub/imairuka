require "test_helper"

class InvoiceTest < ActiveSupport::TestCase
  def setup
    @invoice = Invoice.new(
      invoice_number: "I000001",
      invoice_date: Date.today,
      customer_name: "テスト顧客",
      staff_name: "テスト担当者",
      status: "draft",
      total_amount: 10000
    )
  end

  test "should be valid" do
    assert @invoice.valid?
  end

  test "invoice_number should be present" do
    @invoice.invoice_number = nil
    assert_not @invoice.valid?
  end

  test "invoice_date should be present" do
    @invoice.invoice_date = nil
    assert_not @invoice.valid?
  end

  test "customer_name should be present" do
    @invoice.customer_name = nil
    assert_not @invoice.valid?
  end

  test "staff_name should be present" do
    @invoice.staff_name = nil
    assert_not @invoice.valid?
  end

  test "status should be present" do
    @invoice.status = nil
    assert_not @invoice.valid?
  end

  test "should have many invoice_items" do
    assert_respond_to @invoice, :invoice_items
  end

  test "should have many invoice_histories" do
    assert_respond_to @invoice, :invoice_histories
  end

  test "should accept nested attributes for invoice_items" do
    assert_respond_to @invoice, :invoice_items_attributes=
  end

  test "status_text should return correct text" do
    @invoice.status = "draft"
    assert_equal "下書き", @invoice.status_text
    
    @invoice.status = "sent"
    assert_equal "送付済", @invoice.status_text
    
    @invoice.status = "approved"
    assert_equal "承認済", @invoice.status_text
    
    @invoice.status = "expired"
    assert_equal "失効", @invoice.status_text
  end

  test "status_color should return correct color" do
    @invoice.status = "draft"
    assert_equal "secondary", @invoice.status_color
    
    @invoice.status = "sent"
    assert_equal "info", @invoice.status_color
    
    @invoice.status = "approved"
    assert_equal "success", @invoice.status_color
    
    @invoice.status = "expired"
    assert_equal "danger", @invoice.status_color
  end

  test "should auto-generate invoice_number" do
    invoice = Invoice.new(
      invoice_date: Date.today,
      customer_name: "テスト顧客",
      staff_name: "テスト担当者",
      status: "draft"
    )
    invoice.save!
    assert_match /^I\d{6}$/, invoice.invoice_number
  end

  test "should calculate total_amount_with_tax correctly" do
    @invoice.save!
    
    @invoice.invoice_items.create!(
      product_code: "TEST001",
      product_name: "テスト商品1",
      unit_price: 1000,
      quantity: 2,
      tax_rate: 1
    )
    
    @invoice.invoice_items.create!(
      product_code: "TEST002",
      product_name: "テスト商品2",
      unit_price: 500,
      quantity: 1,
      tax_rate: 2
    )
    
    # 小計: 1000*2 + 500*1 = 2500
    # 消費税: 2000*0.1 + 500*0.08 = 200 + 40 = 240
    # 合計: 2500 + 240 = 2740
    assert_equal 2740, @invoice.total_amount_with_tax
  end
end
