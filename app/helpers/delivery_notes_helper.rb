module DeliveryNotesHelper
  def delivery_note_status_label(status)
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

  def delivery_note_status_color(status)
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
end 