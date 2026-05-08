require "test_helper"

class ReceiptsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @receipt = receipts(:one)
  end

  test "should get index" do
    get receipts_url
    assert_response :success
  end

  test "should get new" do
    get new_receipt_url
    assert_response :success
  end

  test "should create receipt" do
    assert_difference('Receipt.count') do
      post receipts_url, params: { receipt: {
        receipt_number: 'RCP-003',
        issue_date: Date.today,
        customer_name: 'テスト顧客',
        staff_name: 'テスト担当者',
        status: 'draft'
      } }
    end

    assert_redirected_to receipt_url(Receipt.last)
  end

  test "should show receipt" do
    get receipt_url(@receipt)
    assert_response :success
  end

  test "should get edit" do
    get edit_receipt_url(@receipt)
    assert_response :success
  end

  test "should update receipt" do
    patch receipt_url(@receipt), params: { receipt: {
      customer_name: '更新された顧客名'
    } }
    assert_redirected_to receipt_url(@receipt)
  end

  test "should destroy receipt" do
    assert_difference('Receipt.count', -1) do
      delete receipt_url(@receipt)
    end

    assert_redirected_to receipts_url
  end

  test "should get print" do
    get print_receipt_url(@receipt)
    assert_response :success
  end

  test "should get download_pdf" do
    get download_pdf_receipt_url(@receipt)
    assert_response :success
    assert_equal 'application/pdf', response.content_type
  end

  test "should search products" do
    get search_products_receipts_url, params: { q: 'test' }
    assert_response :success
    assert_equal 'application/json', response.content_type
  end
end 