import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["itemRow", "quantity", "totalAmount"]

  connect() {
    // 既存の商品情報を表示
    this.element.querySelectorAll('.product-select').forEach(select => {
      if (select.value) {
        this.updateProductInfo({ target: select })
      }
    })

    // フォーム送信時の処理
    const form = this.element.querySelector('form')
    if (form) {
      form.addEventListener('submit', (event) => {
        const submitButton = form.querySelector('button[type="submit"]')
        if (submitButton) {
          submitButton.disabled = true
          submitButton.innerHTML = `
            <span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
            送信中...
          `
        }
      })
    }

    // totalAmountターゲットが存在する場合のみ更新
    if (this.hasTotalAmountTarget) {
      this.updateTotalAmount()
    }
    this.updateDeleteButtonsVisibility()
  }

  updateDeleteButtonsVisibility() {
    const tbody = this.element.querySelector('#order_items tbody')
    if (!tbody) return

    // 表示中の行を取得
    const rows = Array.from(tbody.querySelectorAll('tr.item-row'))
    const visibleRows = rows.filter(row => {
      const destroyInput = row.querySelector('input[name*="_destroy"]')
      return (!destroyInput || destroyInput.value === '0') && row.style.display !== 'none'
    })

    // 各行の削除ボタンの表示/非表示を設定
    rows.forEach((row) => {
      const deleteButton = row.querySelector('.delete-item')
      if (deleteButton) {
        const destroyInput = row.querySelector('input[name*="_destroy"]')
        const isVisible = !destroyInput || destroyInput.value === '0'
        const isNotHidden = row.style.display !== 'none'
        deleteButton.style.display = (isVisible && isNotHidden && visibleRows.length > 1) ? '' : 'none'
      }
    })
  }

  async handleSubmit(event) {
    event.preventDefault()
    const form = event.target
    const submitButton = form.querySelector('button[type="submit"]')
    
    // 二重送信防止
    if (submitButton.disabled) {
      return
    }
    
    if (submitButton) {
      submitButton.disabled = true
      submitButton.innerHTML = `
        <span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
        送信中...
      `
    }

    try {
      const response = await fetch(form.action, {
        method: form.method,
        body: new FormData(form),
        headers: {
          'Accept': 'text/html',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (response.ok) {
        window.location.href = response.url
      } else {
        const html = await response.text()
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, 'text/html')
        
        // エラーメッセージを表示
        const errorContainer = form.querySelector('.alert-danger')
        if (errorContainer) {
          errorContainer.remove()
        }
        form.insertBefore(doc.querySelector('.alert-danger'), form.firstChild)
        
        // 送信ボタンを元に戻す
        if (submitButton) {
          submitButton.disabled = false
          submitButton.textContent = '更新'
        }
      }
    } catch (error) {
      console.error('送信エラー:', error)
      if (submitButton) {
        submitButton.disabled = false
        submitButton.textContent = '更新'
      }
    }
  }

  updateProductInfo(event) {
    const select = event.target
    const row = select.closest('tr')
    if (!row) return

    const productId = select.value
    const productSelect = row.querySelector('.product-select')
    const quantityInput = row.querySelector('.quantity-input')
    const unitPriceInput = row.querySelector('.unit-price-input')
    const amountInput = row.querySelector('.amount-input')
    const amountDiv = row.querySelector('.amount')
    const unitPriceDiv = row.querySelector('.unit-price')
    const destroyInput = row.querySelector('input[name*="_destroy"]')

    if (productId) {
      // 商品が選択された場合
      if (destroyInput) {
        destroyInput.value = '0'
        row.style.display = ''
      }

      // 既存の商品を探す
      const tbody = this.element.querySelector('#order_items tbody')
      const existingRow = Array.from(tbody.querySelectorAll('tr.item-row')).find(r => {
        if (r === row) return false
        const otherSelect = r.querySelector('.product-select')
        const otherDestroy = r.querySelector('input[name*="_destroy"]')
        return otherSelect && otherSelect.value === productId && (!otherDestroy || otherDestroy.value === '0')
      })

      if (existingRow) {
        // 同じ商品が既に存在する場合は数量を増やす
        const existingQuantityInput = existingRow.querySelector('.quantity-input')
        const existingUnitPriceInput = existingRow.querySelector('.unit-price-input')
        const existingAmountInput = existingRow.querySelector('.amount-input')
        const existingAmountDiv = existingRow.querySelector('.amount')
        
        if (existingQuantityInput && existingUnitPriceInput && existingAmountInput) {
          const currentQuantity = parseInt(existingQuantityInput.value) || 0
          const unitPrice = parseInt(existingUnitPriceInput.value) || 0
          existingQuantityInput.value = currentQuantity + 1
          
          // 金額を更新
          const newAmount = unitPrice * (currentQuantity + 1)
          existingAmountInput.value = newAmount
          if (existingAmountDiv) {
            existingAmountDiv.textContent = new Intl.NumberFormat('ja-JP', { style: 'currency', currency: 'JPY', minimumFractionDigits: 0 }).format(newAmount)
          }
        }
        
        // 現在の行を削除
        if (destroyInput) {
          destroyInput.value = '1'
          row.style.display = 'none'
        }
        
        this.updateTotalAmount()
        this.updateDeleteButtonsVisibility()
      } else {
        // 新しい商品の場合のみ数量を1に設定
        const isNewRow = !row.querySelector('input[name*="[id]"]')
        if (isNewRow && quantityInput) {
          quantityInput.value = '1'
        }
        // 商品情報を取得して設定
        fetch(`/products/${productId}/info`)
          .then(response => response.json())
          .then(data => {
            if (unitPriceInput) {
              unitPriceInput.value = data.unit_price
              // 単価の表示を更新
              if (unitPriceDiv) {
                const formattedPrice = new Intl.NumberFormat('ja-JP', { style: 'currency', currency: 'JPY', minimumFractionDigits: 0 }).format(data.unit_price)
                unitPriceDiv.textContent = formattedPrice
              }
            }
            if (amountInput && quantityInput) {
              const quantity = parseInt(quantityInput.value) || 1
              const amount = data.unit_price * quantity
              amountInput.value = amount
              // 金額の表示を更新
              if (amountDiv) {
                const formattedAmount = new Intl.NumberFormat('ja-JP', { style: 'currency', currency: 'JPY', minimumFractionDigits: 0 }).format(amount)
                amountDiv.textContent = formattedAmount
              }
            }
            this.updateTotalAmount()
            // 商品情報更新後に削除ボタンの表示状態を更新
            this.updateDeleteButtonsVisibility()
          })
          .catch(error => {
            console.error('商品情報取得エラー:', error)
          })
      }
    } else {
      // 商品が選択されていない場合
      if (destroyInput) {
        destroyInput.value = '1'
        row.style.display = 'none'
      }
      this.updateTotalAmount()
      this.updateDeleteButtonsVisibility()
    }
  }

  calculateAmount(event) {
    const input = event.target
    const row = input.closest('tr')
    if (!row) return

    const quantityInput = row.querySelector('.quantity-input')
    const unitPriceInput = row.querySelector('.unit-price-input')
    const amountInput = row.querySelector('.amount-input')
    const amountDiv = row.querySelector('.amount')

    if (quantityInput && unitPriceInput && amountInput) {
      const quantity = parseInt(quantityInput.value) || 0
      const unitPrice = parseInt(unitPriceInput.value) || 0
      const amount = quantity * unitPrice

      amountInput.value = amount
      if (amountDiv) {
        amountDiv.textContent = new Intl.NumberFormat('ja-JP', { style: 'currency', currency: 'JPY', minimumFractionDigits: 0 }).format(amount)
      }
    }

    this.updateTotalAmount()
  }

  updateTotalAmount() {
    const tbody = this.element.querySelector('#order_items tbody')
    if (!tbody) return

    let total = 0
    const rows = tbody.querySelectorAll('tr.item-row')
    
    rows.forEach(row => {
      const destroyInput = row.querySelector('input[name*="_destroy"]')
      if (destroyInput && destroyInput.value === '1') return

      const amountInput = row.querySelector('.amount-input')
      if (amountInput && amountInput.value) {
        total += parseInt(amountInput.value) || 0
      }
    })

    // totalAmountターゲットが存在する場合のみ更新
    if (this.hasTotalAmountTarget) {
      const totalAmountElement = this.totalAmountTarget
      if (totalAmountElement) {
        totalAmountElement.textContent = new Intl.NumberFormat('ja-JP', { style: 'currency', currency: 'JPY', minimumFractionDigits: 0 }).format(total)
      }
    }
  }

  getNextIndex() {
    const tbody = this.element.querySelector('#order_items tbody')
    if (!tbody) return 0

    const existingRows = tbody.querySelectorAll('tr.item-row')
    return existingRows.length
  }

  addItem(event) {
    event.preventDefault()
    
    const tbody = this.element.querySelector('#order_items tbody')
    if (!tbody) return

    const template = this.element.querySelector('#order_items_template')
    if (!template) return

    const newRow = template.content.cloneNode(true)
    const index = this.getNextIndex()

    // インデックスを更新
    newRow.querySelectorAll('[name*="[0]"]').forEach(element => {
      element.name = element.name.replace('[0]', `[${index}]`)
    })

    tbody.appendChild(newRow)
    this.updateDeleteButtonsVisibility()
  }

  deleteItem(event) {
    event.preventDefault()
    
    const button = event.target.closest('.delete-item')
    const row = button.closest('tr')
    if (!row) return

    const destroyInput = row.querySelector('input[name*="_destroy"]')
    if (destroyInput) {
      destroyInput.value = '1'
      row.style.display = 'none'
    } else {
      row.remove()
    }

    this.updateTotalAmount()
    this.updateDeleteButtonsVisibility()
  }
} 