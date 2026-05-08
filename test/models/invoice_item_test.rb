require "test_helper"

class InvoiceItemTest < ActiveSupport::TestCase
  def setup
    @invoice = Invoice.create!(
      invoice_number: "I000001",
      invoice_date: Date.today,
      customer_name: "テスト顧客",
      staff_name: "テスト担当者",
      status: "draft"
    )
    
    @invoice_item = InvoiceItem.new(
      invoice: @invoice,
      product_code: "TEST001",
      product_name: "テスト商品",
      unit_price: 1000,
      quantity: 2,
      tax_rate: 1
    )
  end

  test "should be valid" do
    assert @invoice_item.valid?
  end

  test "product_code should be present" do
    @invoice_item.product_code = nil
    assert_not @invoice_item.valid?
  end

  test "product_name should be present" do
    @invoice_item.product_name = nil
    assert_not @invoice_item.valid?
  end

  test "unit_price should be present" do
    @invoice_item.unit_price = nil
    assert_not @invoice_item.valid?
  end

  test "unit_price should be greater than or equal to 0" do
    @invoice_item.unit_price = -1
    assert_not @invoice_item.valid?
  end

  test "quantity should be present" do
    @invoice_item.quantity = nil
    assert_not @invoice_item.valid?
  end

  test "quantity should be greater than 0" do
    @invoice_item.quantity = 0
    assert_not @invoice_item.valid?
  end

  test "tax_rate should be present" do
    @invoice_item.tax_rate = nil
    assert_not @invoice_item.valid?
  end

  test "tax_rate should be included in valid values" do
    @invoice_item.tax_rate = 5
    assert_not @invoice_item.valid?
  end

  test "should belong to invoice" do
    assert_respond_to @invoice_item, :invoice
  end

  test "should calculate amount before save" do
    @invoice_item.save!
    assert_equal 2000, @invoice_item.amount
  end

  test "tax_rate_text should return correct text" do
    @invoice_item.tax_rate = 1
    assert_equal "10%", @invoice_item.tax_rate_text
    
    @invoice_item.tax_rate = 2
    assert_equal "8% (軽減税率)", @invoice_item.tax_rate_text
    
    @invoice_item.tax_rate = 3
    assert_equal "8%", @invoice_item.tax_rate_text
    
    @invoice_item.tax_rate = 4
    assert_equal "0%", @invoice_item.tax_rate_text
  end

  test "amount_with_tax should calculate correctly" do
    @invoice_item.unit_price = 1000
    @invoice_item.quantity = 1
    @invoice_item.amount = 1000
    
    @invoice_item.tax_rate = 1
    assert_equal 1100, @invoice_item.amount_with_tax
    
    @invoice_item.tax_rate = 2
    assert_equal 1080, @invoice_item.amount_with_tax
    
    @invoice_item.tax_rate = 3
    assert_equal 1080, @invoice_item.amount_with_tax
    
    @invoice_item.tax_rate = 4
    assert_equal 1000, @invoice_item.amount_with_tax
  end
end
