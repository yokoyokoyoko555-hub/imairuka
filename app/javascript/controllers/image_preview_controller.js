import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "container"]

  connect() {
    console.log("Image preview controller connected")
  }

  preview(event) {
    const file = event.target.files[0]
    if (!file) return

    // ファイルタイプのチェック
    if (!file.type.startsWith('image/')) {
      alert('画像ファイルを選択してください')
      return
    }

    // ファイルサイズのチェック（5MB）
    if (file.size > 5 * 1024 * 1024) {
      alert('画像サイズは5MB以下にしてください')
      return
    }

    const reader = new FileReader()
    reader.onload = (e) => {
      this.previewTarget.src = e.target.result
      this.containerTarget.style.display = 'block'
    }
    reader.readAsDataURL(file)
  }

  remove() {
    this.inputTarget.value = ''
    this.previewTarget.src = ''
    this.containerTarget.style.display = 'none'
  }
} 