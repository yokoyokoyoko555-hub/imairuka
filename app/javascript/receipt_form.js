// 領収書フォーム管理
class ReceiptForm {
  constructor() {
    this.init();
  }

  init() {
    this.bindEvents();
    this.reindexRows();
  }

  // HTMLエスケープ
  escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  // 商品の読み込み
  async loadProducts(query = '') {
    try {
      const response = await fetch(`/receipts/search_products?q=${encodeURIComponent(query)}`);
      const products = await response.json();
      this.displayProducts(products, query);
    } catch (error) {
      console.error('商品読み込みエラー:', error);
      this.displayError();
    }
  }

  // 商品リストの表示
  displayProducts(products, query = '') {
    const tbody = document.getElementById('productList');
    if (!tbody) return;

    if (products.length === 0) {
      const message = query ? '商品が見つかりません' : '商品が登録されていません';
      tbody.innerHTML = `<tr><td class="text-center" colspan="4">${message}</td></tr>`;
      return;
    }

    tbody.innerHTML = products.map(product => `
      <tr>
        <td>${this.escapeHtml(product.code)}</td>
        <td>${this.escapeHtml(product.name)}</td>
        <td class="text-end">¥${product.unit_price ? product.unit_price.toLocaleString() : '0'}</td>
        <td>
          <button class="btn btn-sm btn-outline-primary add-item" type="button" 
                  data-product-code="${this.escapeHtml(product.code)}" 
                  data-product-name="${this.escapeHtml(product.name)}" 
                  data-unit-price="${product.unit_price || 0}"
                  data-tax-rate="${product.tax_rate !== undefined && product.tax_rate !== '' && product.tax_rate !== 'null' ? product.tax_rate : null}">
            <i class="bi bi-plus me-1"></i>追加
          </button>
        </td>
      </tr>
    `).join('');

    this.attachAddItemListeners();
  }

  // エラー表示
  displayError() {
    const tbody = document.getElementById('productList');
    if (tbody) {
      tbody.innerHTML = '<tr><td class="text-center" colspan="4">商品の読み込みに失敗しました</td></tr>';
    }
  }

  // 商品追加ボタンのイベントリスナー設定
  attachAddItemListeners() {
    document.querySelectorAll('.add-item').forEach(button => {
      button.addEventListener('click', () => this.addProductToReceipt(button));
    });
  }

  // 領収書に商品を追加
  addProductToReceipt(button) {
    const tbody = document.getElementById('receipt-items');
    if (!tbody) return;

    console.log('商品追加処理開始');

    // 「商品を追加してください」メッセージを非表示
    this.hideNoItemsMessage();

    // 削除マークが付いた商品の数をカウントして、新しいインデックスを計算
    const destroyFields = document.querySelectorAll('input[name*="[_destroy]"]');
    const destroyedCount = destroyFields.length;
    const visibleRows = tbody.querySelectorAll('tr.item-row:not([style*="display: none"])');
    const index = visibleRows.length + destroyedCount;
    
    console.log('削除マークが付いた商品数:', destroyedCount);
    console.log('表示されている商品行数:', visibleRows.length);
    console.log('新しい商品のインデックス:', index);
    
    const productCode = button.dataset.productCode;
    const productName = button.dataset.productName;
    const unitPrice = parseInt(button.dataset.unitPrice);
    const taxRate = button.dataset.taxRate !== undefined && button.dataset.taxRate !== '' && button.dataset.taxRate !== 'null' ? parseInt(button.dataset.taxRate) : null;

    console.log('追加する商品情報:', {
      productCode,
      productName,
      unitPrice,
      taxRate
    });

    const row = document.createElement('tr');
    row.className = 'item-row';
    row.innerHTML = `
      <td><input type="text" name="receipt[receipt_items_attributes][${index}][product_code]" value="${this.escapeHtml(productCode)}" class="form-control" required maxlength="20"></td>
      <td><input type="text" name="receipt[receipt_items_attributes][${index}][product_name]" value="${this.escapeHtml(productName)}" class="form-control" required maxlength="100"></td>
      <td class="text-end"><input type="number" name="receipt[receipt_items_attributes][${index}][unit_price]" value="${unitPrice}" class="form-control text-end" min="0" step="1" required></td>
      <td class="text-end"><input type="number" name="receipt[receipt_items_attributes][${index}][quantity]" value="1" class="form-control text-end" min="1" step="1" required></td>
      <td class="text-end"><span class="item-amount">¥${unitPrice.toLocaleString()}</span></td>
      <td><select name="receipt[receipt_items_attributes][${index}][tax_rate]" class="form-select">
        <option value=""${taxRate === null ? ' selected' : ''}>選択してください</option>
        <option value="1"${taxRate === 1 ? ' selected' : ''}>10%</option>
        <option value="2"${taxRate === 2 ? ' selected' : ''}>8% (軽減税率)</option>
        <option value="3"${taxRate === 3 ? ' selected' : ''}>8%</option>
        <option value="4"${taxRate === 4 ? ' selected' : ''}>0%</option>
      </select></td>
      <td><button type="button" class="btn btn-sm btn-outline-danger remove-item"><i class="bi bi-trash"></i></button></td>
    `;

    console.log('作成した行のHTML:', row.innerHTML);

    tbody.appendChild(row);
    this.setupRowEventListeners(row);
    this.updateTotalAmount();
    this.closeModal();
    
    console.log('商品追加処理完了');
  }

  // 行のイベントリスナー設定
  setupRowEventListeners(row) {
    console.log('setupRowEventListeners 呼び出し');
    
    const removeBtn = row.querySelector('.remove-item');
    console.log('削除ボタン:', removeBtn);
    
    if (removeBtn) {
      console.log('削除ボタンにイベントリスナーを設定');
      removeBtn.addEventListener('click', () => {
        console.log('削除ボタンがクリックされました');
        
        // 既存の商品（IDがある）の場合は削除マークを付けて非表示にする
        const idInput = row.querySelector('input[name*="[id]"]');
        console.log('IDフィールド:', idInput);
        console.log('ID値:', idInput ? idInput.value : 'なし');
        
        if (idInput && idInput.value) {
          console.log('既存の商品を削除マーク付きで非表示にします');
          // 削除マークを付ける
          const destroyInput = document.createElement('input');
          destroyInput.type = 'hidden';
          destroyInput.name = idInput.name.replace('[id]', '[_destroy]');
          destroyInput.value = '1';
          row.appendChild(destroyInput);
          
          console.log('削除マークを作成:', destroyInput.name, destroyInput.value);
          
          // 行を非表示にする（削除しない）
          row.style.display = 'none';
        } else {
          console.log('新規商品をDOMから削除します');
          // 新しく追加した商品の場合はDOMから削除
          row.remove();
        }
        
        this.updateTotalAmount();
        this.reindexRows();
        
        // 商品がなくなった場合にメッセージを再表示
        this.checkAndShowNoItemsMessage();
      });
    } else {
      console.log('削除ボタンが見つかりません');
    }

    const inputs = row.querySelectorAll('input[type="number"]');
    inputs.forEach(input => {
      input.addEventListener('change', () => this.updateRowAmount(row));
    });

    // 税率プルダウン変更時も再計算
    const taxSelect = row.querySelector('select[name*="[tax_rate]"]');
    if (taxSelect) {
      taxSelect.addEventListener('change', () => this.updateTotalAmount());
    }
  }

  // 商品がない場合にメッセージを表示する処理
  checkAndShowNoItemsMessage() {
    const tbody = document.getElementById('receipt-items');
    if (!tbody) return;

    const visibleRows = tbody.querySelectorAll('tr.item-row:not([style*="display: none"])');
    if (visibleRows.length === 0) {
      this.showNoItemsMessage();
    }
  }

  showNoItemsMessage() {
    const tbody = document.getElementById('receipt-items');
    if (!tbody) return;

    // 既存のメッセージを削除
    this.hideNoItemsMessage();
    
    // 新しいメッセージを作成
    const messageHtml = `
      <tr id="no-items-message">
        <td class="text-center" colspan="7">
          <div class="text-muted">
            <i class="bi bi-cart me-2"></i>商品を追加してください
          </div>
        </td>
      </tr>
    `;
    
    tbody.insertAdjacentHTML('beforeend', messageHtml);
  }

  hideNoItemsMessage() {
    const tbody = document.getElementById('receipt-items');
    if (!tbody) return;

    const noItemsMessage = tbody.querySelector('#no-items-message');
    if (noItemsMessage) {
      noItemsMessage.remove();
    }
  }

  closeModal() {
    const modal = bootstrap.Modal.getInstance(document.getElementById('addItemModal'));
    if (modal) {
      modal.hide();
    }
  }

  reindexRows() {
    const tbody = document.getElementById('receipt-items');
    if (!tbody) return;

    const visibleRows = tbody.querySelectorAll('tr.item-row:not([style*="display: none"])');
    visibleRows.forEach((row, index) => {
      const inputs = row.querySelectorAll('input, select');
      inputs.forEach(input => {
        const name = input.getAttribute('name');
        if (name) {
          const newName = name.replace(/\[\d+\]/, `[${index}]`);
          input.setAttribute('name', newName);
        }
      });
    });
  }

  updateRowAmount(row) {
    const unitPrice = parseInt(row.querySelector('input[name*="[unit_price]"]').value) || 0;
    const quantity = parseInt(row.querySelector('input[name*="[quantity]"]').value) || 0;
    const amount = unitPrice * quantity;
    row.querySelector('.item-amount').textContent = '¥' + amount.toLocaleString();
    this.updateTotalAmount();
  }

  updateTotalAmount() {
    let total = 0;
    document.querySelectorAll('#receipt-items tr.item-row:not([style*="display: none"])').forEach(row => {
      const unitPrice = parseInt(row.querySelector('input[name*="[unit_price]"]').value) || 0;
      const quantity = parseInt(row.querySelector('input[name*="[quantity]"]').value) || 0;
      const amount = unitPrice * quantity;
      total += amount;
    });
    
    const totalElement = document.getElementById('total-amount');
    if (totalElement) {
      totalElement.textContent = '¥' + total.toLocaleString();
    }
    // hiddenフィールドも更新
    const totalHidden = document.querySelector('input[name="receipt[total_amount]"]');
    if (totalHidden) {
      totalHidden.value = total;
    }
  }

  // プレビュー機能
  openPreview() {
    // 正しいフォームを選択（領収書フォーム）
    const form = document.querySelector('form[action*="/receipts"]');
    if (!form) {
      console.error('領収書フォームが見つかりません');
      return;
    }
    
    const formData = new FormData(form);
    
    const subject = formData.get('receipt[subject]');
    
    const receiptData = {
      receipt_number: formData.get('receipt[receipt_number]') || '',
      issue_date: formData.get('receipt[issue_date]') || '',
      customer_name: formData.get('receipt[customer_name]') || '',
      customer_address: formData.get('receipt[customer_address]') || '',
      subject: subject || '',
      staff_name: formData.get('receipt[staff_name]') || '',
      payment_method: formData.get('receipt[payment_method]') || '',
      payment_date: formData.get('receipt[payment_date]') || '',
      status: formData.get('receipt[status]') || '',
      notes: formData.get('receipt[notes]') || '',
      total_amount: 0,
      items: []
    };

    document.querySelectorAll('#receipt-items tr.item-row').forEach(row => {
      const productCode = row.querySelector('input[name*="[product_code]"]')?.value || '';
      const productName = row.querySelector('input[name*="[product_name]"]')?.value || '';
      const unitPrice = parseInt(row.querySelector('input[name*="[unit_price]"]')?.value) || 0;
      const quantity = parseInt(row.querySelector('input[name*="[quantity]"]')?.value) || 0;
      const amount = unitPrice * quantity;
      const taxRate = row.querySelector('select[name*="[tax_rate]"]')?.value || '';

      if (productCode && productName) {
        receiptData.items.push({
          product_code: productCode,
          product_name: productName,
          unit_price: unitPrice,
          quantity: quantity,
          amount: amount,
          tax_rate: taxRate !== '' ? parseInt(taxRate) : null
        });
        receiptData.total_amount += amount;
      }
    });

    const previewUrl = '/receipts/print?' + new URLSearchParams({
      receipt_data: JSON.stringify(receiptData)
    });

    window.open(previewUrl, '_blank');
  }

  // PDFダウンロード機能
  downloadPDF() {
    // 正しいフォームを選択（領収書フォーム）
    const form = document.querySelector('form[action*="/receipts"]');
    if (!form) {
      console.error('領収書フォームが見つかりません');
      return;
    }
    
    const formData = new FormData(form);
    
    const subject = formData.get('receipt[subject]');
    
    const receiptData = {
      receipt_number: formData.get('receipt[receipt_number]') || '',
      issue_date: formData.get('receipt[issue_date]') || '',
      customer_name: formData.get('receipt[customer_name]') || '',
      customer_address: formData.get('receipt[customer_address]') || '',
      subject: subject || '',
      staff_name: formData.get('receipt[staff_name]') || '',
      payment_method: formData.get('receipt[payment_method]') || '',
      payment_date: formData.get('receipt[payment_date]') || '',
      status: formData.get('receipt[status]') || '',
      notes: formData.get('receipt[notes]') || '',
      total_amount: 0,
      items: []
    };

    document.querySelectorAll('#receipt-items tr.item-row').forEach(row => {
      const productCode = row.querySelector('input[name*="[product_code]"]')?.value || '';
      const productName = row.querySelector('input[name*="[product_name]"]')?.value || '';
      const unitPrice = parseInt(row.querySelector('input[name*="[unit_price]"]')?.value) || 0;
      const quantity = parseInt(row.querySelector('input[name*="[quantity]"]')?.value) || 0;
      const amount = unitPrice * quantity;
      const taxRate = row.querySelector('select[name*="[tax_rate]"]')?.value || '';

      if (productCode && productName) {
        receiptData.items.push({
          product_code: productCode,
          product_name: productName,
          unit_price: unitPrice,
          quantity: quantity,
          amount: amount,
          tax_rate: taxRate !== '' ? parseInt(taxRate) : null
        });
        receiptData.total_amount += amount;
      }
    });

    const pdfUrl = '/receipts/download_pdf?' + new URLSearchParams({
      receipt_data: JSON.stringify(receiptData)
    });

    // ダウンロードを強制するために新しいウィンドウで開く
    window.location.href = pdfUrl;
  }



  restoreItemsOnError() {
    const tbody = document.getElementById('receipt-items');
    if (!tbody) {
      return;
    }

    // 既存の商品行があるかチェック
    const existingRows = tbody.querySelectorAll('tr.item-row');
    
    if (existingRows.length > 0) {
      // 既存の商品行がある場合は、それらにイベントリスナーを設定
      existingRows.forEach((row, index) => {
        this.setupRowEventListeners(row);
      });
      
      // 「商品を追加してください」メッセージを非表示
      const noItemsMessage = document.getElementById('no-items-message');
      if (noItemsMessage) {
        noItemsMessage.style.display = 'none';
      }
      
      // 合計金額を再計算
      this.updateTotalAmount();
    }
  }

  // 削除マークが付いた商品の行を非表示にする
  hideDestroyedItems() {
    const tbody = document.getElementById('receipt-items');
    if (!tbody) return;

    const destroyFields = tbody.querySelectorAll('input[name*="[_destroy]"]');
    destroyFields.forEach(field => {
      if (field.value === '1') {
        const row = field.closest('tr.item-row');
        if (row) {
          row.style.display = 'none';
        }
      }
    });
  }

  bindEvents() {
    // ページ読み込み時に削除マークが付いた商品の行を非表示にする
    this.hideDestroyedItems();
    
    // エラー時の商品データ復元
    this.restoreItemsOnError();
    
    // 一時保存ボタンがクリックされた時にrequired属性を削除
    const saveDraftButton = document.querySelector('input[name="save_draft"]');
    if (saveDraftButton) {
      saveDraftButton.addEventListener('click', function() {
        // 一時保存時はrequired属性を削除
        document.querySelectorAll('[required]').forEach(function(field) {
          field.removeAttribute('required');
        });
      });
    }
    
    // フォーム送信時の処理
    const form = document.querySelector('form');
    if (form) {
      form.addEventListener('submit', (e) => {
        // 削除マークが付いた商品の行を非表示にして、削除マークを送信できるようにする
        const hiddenRows = document.querySelectorAll('#receipt-items tr.item-row[style*="display: none"]');
        hiddenRows.forEach(row => {
          const idField = row.querySelector('input[name*="[id]"]');
          const destroyField = row.querySelector('input[name*="[_destroy]"]');
          
          if (idField && idField.value && destroyField && destroyField.value === '1') {
            // 削除マークが付いた商品の行を非表示のままにする（削除しない）
          }
        });
      });
    }

    // モーダルイベント
    const modal = document.getElementById('addItemModal');
    if (modal) {
      modal.addEventListener('show.bs.modal', () => this.loadProducts());
    }

    // 検索機能
    const searchInput = document.getElementById('productSearch');
    if (searchInput) {
      let searchTimeout;
      searchInput.addEventListener('input', () => {
        clearTimeout(searchTimeout);
        const query = searchInput.value.trim();
        
        searchTimeout = setTimeout(() => this.loadProducts(query), 300);
      });
    }

    // プレビューボタン（新規作成ページ）
    const previewBtn = document.getElementById('preview-btn');
    if (previewBtn) {
      previewBtn.addEventListener('click', () => this.openPreview());
    }

    // PDFダウンロードボタン（新規作成ページ）
    const pdfBtn = document.getElementById('pdf-btn');
    if (pdfBtn) {
      pdfBtn.addEventListener('click', () => this.downloadPDF());
    }

    // プレビューボタン（編集ページ - リンク）
    const previewLink = document.querySelector('a[href*="/print"]');
    if (previewLink) {
      previewLink.addEventListener('click', (e) => {
        e.preventDefault();
        this.openPreview();
      });
    }

    // 既存の数値入力
    document.querySelectorAll('input[type="number"]').forEach(input => {
      input.addEventListener('change', () => this.updateRowAmount(input.closest('tr')));
    });

    // 既存の税率プルダウンにも再計算イベントを追加
    document.querySelectorAll('select[name*="[tax_rate]"]').forEach(select => {
      select.addEventListener('change', () => this.updateTotalAmount());
    });
  }
}

document.addEventListener('DOMContentLoaded', () => {
  new ReceiptForm();
}); 