import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["colorInput", "textInput", "container"]

  connect() {
    // 初期値の同期
    if (this.hasColorInputTarget && this.hasTextInputTarget) {
      this.textInputTarget.value = this.colorInputTarget.value
    }
  }

  updateText(event) {
    if (this.hasTextInputTarget) {
      this.textInputTarget.value = event.target.value
    }
  }

  updateColor(event) {
    const value = event.target.value
    if (this.isValidColor(value) && this.hasColorInputTarget) {
      this.colorInputTarget.value = value
    }
  }

  isValidColor(color) {
    return /^#[0-9A-F]{6}$/i.test(color)
  }
} 