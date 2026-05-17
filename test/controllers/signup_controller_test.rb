require "test_helper"

class SignupControllerTest < ActionDispatch::IntegrationTest
  test "vendor signup creates pending contract candidate linked to vendor" do
    vendor = Vendor.create!(
      code: "VENDOR-FLOW",
      name: "テストベンダー",
      contact_name: "山田 太郎",
      email: "vendor-flow@example.com",
      status: "active"
    )

    assert_difference("Company.count", 1) do
      post signup_path, params: {
        company: {
          name: "ベンダー経由テスト株式会社",
          representative: "佐藤 花子",
          email: "vendor-company@example.com",
          phone: "0312345678",
          postal_code: "1000001",
          invoice_number: "T1234567890123",
          address: "東京都千代田区1-1-1",
          business_type: "小売業",
          vendor_code: " vendor-flow "
        }
      }
    end

    company = Company.order(:created_at).last
    assert_redirected_to signup_complete_path
    assert_equal vendor, company.vendor
    assert_equal "vendor", company.sales_channel
    assert_equal "vendor", company.billing_payer_type
    assert_equal "pending_review", company.contract_status
    assert_equal "unbilled", company.billing_status
    assert_equal Company::DEFAULT_CONTRACT_AMOUNT, company.contract_amount
    assert_equal Company::DEFAULT_CONTRACT_MONTHS, company.contract_months
  end

  test "unknown vendor code does not create contract candidate" do
    assert_no_difference("Company.count") do
      post signup_path, params: {
        company: {
          name: "存在しないベンダー申込株式会社",
          representative: "佐藤 花子",
          email: "unknown-vendor@example.com",
          phone: "0312345678",
          postal_code: "1000001",
          invoice_number: "T1234567890123",
          address: "東京都千代田区1-1-1",
          business_type: "小売業",
          vendor_code: "UNKNOWN-VENDOR"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "ベンダーコード"
  end
end
