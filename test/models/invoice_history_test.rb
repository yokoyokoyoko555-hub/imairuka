require "test_helper"

class InvoiceHistoryTest < ActiveSupport::TestCase
  def setup
    @invoice = Invoice.create!(
      invoice_number: "I000001",
      invoice_date: Date.today,
      customer_name: "テスト顧客",
      staff_name: "テスト担当者",
      status: "draft"
    )
    
    @invoice_history = InvoiceHistory.new(
      invoice: @invoice,
      action: "請求書作成",
      user: "テスト担当者"
    )
  end

  test "should be valid" do
    assert @invoice_history.valid?
  end

  test "action should be present" do
    @invoice_history.action = nil
    assert_not @invoice_history.valid?
  end

  test "user should be present" do
    @invoice_history.user = nil
    assert_not @invoice_history.valid?
  end

  test "should belong to invoice" do
    assert_respond_to @invoice_history, :invoice
  end

  test "description should return formatted string" do
    @invoice_history.save!
    expected = "請求書作成 - テスト担当者 (#{@invoice_history.created_at.strftime('%Y/%m/%d %H:%M')})"
    assert_equal expected, @invoice_history.description
  end
end
