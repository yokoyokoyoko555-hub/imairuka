module ReceiptsHelper
  def receipt_status_color(status)
    case status
    when 'pending'
      'secondary'
    when 'sent'
      'info'
    when 'waiting_payment'
      'warning'
    when 'paid'
      'success'
    else
      'secondary'
    end
  end

  def receipt_status_label(status)
    case status
    when 'pending'
      '送付待ち'
    when 'sent'
      '送付済み'
    when 'waiting_payment'
      '入金待ち'
    when 'paid'
      '入金済み'
    else
      '不明'
    end
  end

  def receipt_tax_rate_label(tax_rate)
    case tax_rate.to_i
    when 1
      '10%'
    when 2
      '8% (軽減税率)'
    when 3
      '8%'
    when 4
      '0%'
    else
      '未設定'
    end
  end

  def format_date(date)
    date&.strftime('%Y年%m月%d日')
  end

  def format_amount(amount)
    number_to_currency(amount, unit: '¥', precision: 0, format: '%u%n')
  end
end 