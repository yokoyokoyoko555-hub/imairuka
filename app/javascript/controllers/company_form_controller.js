import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.setupPhoneNumberFormatting()
  }

  setupPhoneNumberFormatting() {
    const phoneField = this.element.querySelector('input[name="company[phone]"]')
    if (phoneField) {
      phoneField.addEventListener('input', (e) => {
        const value = e.target.value
        
        // 数字とハイフン以外が含まれているかチェック
        if (value.match(/[^\d-]/)) {
          // エラーメッセージを表示（実際のバリデーションはサーバー側で行う）
          return
        }
        
        // ハイフンを削除して数字のみにする
        let cleanValue = value.replace(/[^\d]/g, '')
        
        // 10桁または11桁に制限
        if (cleanValue.length > 11) {
          cleanValue = cleanValue.substring(0, 11)
        }
        
        e.target.value = cleanValue
      })
    }
  }
} 