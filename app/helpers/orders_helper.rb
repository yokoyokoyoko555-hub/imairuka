module OrdersHelper
  def active_class(path)
    current_page?(path) ? 'active' : ''
  end

  def status_color(code)
    'primary'  # すべてのステータスで青色を使用
  end

  def status_label(status)
    case status
    when 'received'
      '受注済'
    when 'ordered'
      '発注済'
    when 'delivered'
      '納品済'
    when 'billed'
      '請求済'
    when 'paid'
      '入金済'
    else
      '不明'
    end
  end

  def purchase_status_color(status)
    case status
    when 'ordered'
      'info'
    when 'received'
      'success'
    when 'paid'
      'secondary'
    else
      'light'
    end
  end

  def purchase_status_label(status)
    case status
    when 'ordered'
      '発注済'
    when 'received'
      '入荷済'
    when 'paid'
      '支払済'
    else
      '不明'
    end
  end

  def receiving_status_color(status)
    case status
    when 'ordered'
      'warning'  # 発注済：黄色
    when 'received'
      'success'  # 入荷済：緑色
    when 'paid'
      'info'     # 支払済：青色
    else
      'light'    # その他：グレー
    end
  end

  def receiving_status_label(status)
    case status
    when 'ordered'
      '発注済'
    when 'received'
      '入荷済'
    when 'paid'
      '支払済'
    else
      '不明'
    end
  end

  def format_amount(amount)
    number_to_currency(amount, unit: '¥', precision: 0, format: '%u%n')
  end

  def payment_status_color(status)
    case status
    when 'paid'
      'success'
    when 'partial'
      'warning'
    when 'unpaid'
      'danger'
    else
      'secondary'
    end
  end

  def payment_status_label(status)
    case status
    when 'paid'
      '支払済'
    when 'partial'
      '一部支払'
    when 'unpaid'
      '未払'
    else
      '不明'
    end
  end
end 