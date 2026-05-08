require "test_helper"

class ReceiptTest < ActiveSupport::TestCase
  def setup
    @receipt = receipts(:one)
  end

  test "should be valid" do
    assert @receipt.valid?
  end

  test "receipt_number should be present" do
    @receipt.receipt_number = nil
    assert_not @receipt.valid?
  end

  test "issue_date should be present" do
    @receipt.issue_date = nil
    assert_not @receipt.valid?
  end

  test "customer_name should be present" do
    @receipt.customer_name = nil
    assert_not @receipt.valid?
  end

  test "staff_name should be present" do
    @receipt.staff_name = nil
    assert_not @receipt.valid?
  end

  test "status should be valid" do
    @receipt.status = 'invalid_status'
    assert_not @receipt.valid?
  end

  test "should calculate total amount with tax" do
    @receipt.receipt_items.create!(
      product_code: 'TEST-001',
      product_name: 'テスト商品',
      unit_price: 1000,
      quantity: 2,
      tax_rate: 1
    )
    
    expected_total = 2200 # 1000 * 2 * 1.1 (10% tax)
    assert_equal expected_total, @receipt.total_amount_with_tax
  end

  test "should handle different tax rates" do
    @receipt.receipt_items.create!(
      product_code: 'TEST-002',
      product_name: 'テスト商品2',
      unit_price: 1000,
      quantity: 1,
      tax_rate: 2
    )
    
    expected_total = 1080 # 1000 * 1.08 (8% tax)
    assert_equal expected_total, @receipt.total_amount_with_tax
  end

  test "should handle zero tax rate" do
    @receipt.receipt_items.create!(
      product_code: 'TEST-003',
      product_name: 'テスト商品3',
      unit_price: 1000,
      quantity: 1,
      tax_rate: 4
    )
    
    expected_total = 1000 # 1000 * 1.0 (0% tax)
    assert_equal expected_total, @receipt.total_amount_with_tax
  end

  test "should return zero for empty items" do
    @receipt.receipt_items.destroy_all
    assert_equal 0, @receipt.total_amount_with_tax
  end

  test "should create history on create" do
    receipt = Receipt.new(
      receipt_number: 'RCP-001',
      issue_date: Date.today,
      customer_name: 'テスト顧客',
      staff_name: 'テスト担当者',
      status: 'draft'
    )
    
    assert_difference 'ReceiptHistory.count' do
      receipt.save!
    end
  end

  test "should create history on update" do
    assert_difference 'ReceiptHistory.count' do
      @receipt.update!(customer_name: '更新された顧客名')
    end
  end
end
