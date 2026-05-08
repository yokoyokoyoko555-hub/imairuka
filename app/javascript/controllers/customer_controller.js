import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  deleteCustomer(event) {
    const ordersCount = parseInt(event.currentTarget.dataset.customerOrdersCount)
    
    if (ordersCount > 0) {
      event.preventDefault()
      alert("案件が紐づいているため削除できません。先に案件を削除してください。")
      return false
    }
    
    // 案件が紐づいていない場合は通常の削除確認ダイアログを表示
    return confirm("この顧客を削除してもよろしいですか？")
  }
} 