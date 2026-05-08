module ApplicationHelper
  def active_class(path)
    current_page?(path) ? 'active' : ''
  end

  def order_status_badge_class(status)
    'bg-primary'  # すべてのステータスで青色を使用
  end

  def order_status_text(status)
    case status
    when 'received'
      '受付済'
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

  # 曜日の日本語表記を取得
  def japanese_weekday(date)
    weekdays = %w[日 月 火 水 木 金 土]
    weekdays[date.wday]
  end

  # 日付を日本語フォーマットで表示（日付のみ）
  def format_date(date)
    return "-" unless date.present?
    date.to_date.strftime("%Y年%m月%d日(#{japanese_weekday(date.to_date)})")
  end

  # 日付と時刻を日本語フォーマットで表示
  def format_datetime(datetime)
    return "-" unless datetime.present?
    datetime.to_time.strftime("%Y年%m月%d日(#{japanese_weekday(datetime.to_time)}) %H:%M")
  end
end
