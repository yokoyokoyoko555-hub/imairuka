// 一括操作機能
class BulkActions {
  constructor() {
    this.init();
  }

  init() {
    this.bindEvents();
  }

  // イベントのバインド
  bindEvents() {
    // 全選択チェックボックス
    const selectAllCheckboxes = document.querySelectorAll('[data-bulk-actions-target="selectAll"]');
    selectAllCheckboxes.forEach(checkbox => {
      checkbox.addEventListener('change', () => this.toggleSelectAll(checkbox));
    });

    // 個別チェックボックス
    const checkboxes = document.querySelectorAll('[data-bulk-actions-target="checkbox"]');
    checkboxes.forEach(checkbox => {
      checkbox.addEventListener('change', () => this.updateActionButton());
    });

    // 一括削除ボタン
    const deleteButtons = document.querySelectorAll('[data-action="bulkDelete"]');
    deleteButtons.forEach(button => {
      button.addEventListener('click', (e) => this.bulkDelete(e));
    });

    // 一括インポートボタン
    const importButtons = document.querySelectorAll('[data-action="bulkImport"]');
    importButtons.forEach(button => {
      button.addEventListener('click', (e) => this.bulkImport(e));
    });

    // 一括エクスポートボタン
    const exportButtons = document.querySelectorAll('[data-action="bulkExport"]');
    exportButtons.forEach(button => {
      button.addEventListener('click', (e) => this.bulkExport(e));
    });
  }

  // 全選択/全解除
  toggleSelectAll(selectAllCheckbox) {
    const table = selectAllCheckbox.closest('table');
    const checkboxes = table.querySelectorAll('[data-bulk-actions-target="checkbox"]');
    const isChecked = selectAllCheckbox.checked;
    
    checkboxes.forEach(checkbox => {
      checkbox.checked = isChecked;
    });
    
    this.updateActionButton();
  }

  // アクションボタンの有効/無効を更新
  updateActionButton() {
    const tables = document.querySelectorAll('table');
    
    tables.forEach(table => {
      const selectAllCheckbox = table.querySelector('[data-bulk-actions-target="selectAll"]');
      const checkboxes = table.querySelectorAll('[data-bulk-actions-target="checkbox"]');
      
      if (!selectAllCheckbox || checkboxes.length === 0) return;
      
      // 同じページ内のアクションボタンを探す
      const actionButton = document.querySelector('[data-bulk-actions-target="actionButton"]');
      if (!actionButton) return;
      
      const checkedCount = Array.from(checkboxes).filter(checkbox => checkbox.checked).length;
      const totalCount = checkboxes.length;
      
      // 全選択チェックボックスの状態を更新
      selectAllCheckbox.checked = checkedCount === totalCount && totalCount > 0;
      
      // 一括操作ボタンの有効/無効を更新
      actionButton.disabled = checkedCount === 0;
    });
  }

  // 一括削除
  bulkDelete(event) {
    event.preventDefault();
    
    const table = event.target.closest('table') || document.querySelector('table');
    const checkboxes = table.querySelectorAll('[data-bulk-actions-target="checkbox"]:checked');
    const selectedItems = Array.from(checkboxes).map(checkbox => checkbox.value);
    
    if (selectedItems.length === 0) {
      return;
    }
    
    if (confirm(`${selectedItems.length}件の項目を削除してもよろしいですか？\nこの操作は取り消せません。`)) {
      // 現在のページのパスに基づいてルートを決定
      const currentPath = window.location.pathname;
      let deleteRoute = '/bulk_delete';
      
      if (currentPath.includes('/orders')) {
        deleteRoute = '/orders/bulk_delete';
      } else if (currentPath.includes('/customers')) {
        deleteRoute = '/customers/bulk_delete';
      } else if (currentPath.includes('/products')) {
        deleteRoute = '/products/bulk_delete';
      }
      
      this.submitForm(deleteRoute, selectedItems);
    }
  }

  // 一括インポート
  bulkImport(event) {
    event.preventDefault();
    
    const table = event.target.closest('table') || document.querySelector('table');
    const checkboxes = table.querySelectorAll('[data-bulk-actions-target="checkbox"]:checked');
    const selectedItems = Array.from(checkboxes).map(checkbox => checkbox.value);
    
    if (selectedItems.length === 0) {
      return;
    }
    
    if (confirm(`${selectedItems.length}件の項目をインポートしますか？`)) {
      // 現在のページのパスに基づいてルートを決定
      const currentPath = window.location.pathname;
      let importRoute = '/bulk_import';
      
      if (currentPath.includes('/customers')) {
        importRoute = '/customers/bulk_import';
      } else if (currentPath.includes('/products')) {
        importRoute = '/products/bulk_import';
      }
      
      this.submitForm(importRoute, selectedItems);
    }
  }

  // 一括エクスポート
  bulkExport(event) {
    event.preventDefault();
    
    const table = event.target.closest('table') || document.querySelector('table');
    const checkboxes = table.querySelectorAll('[data-bulk-actions-target="checkbox"]:checked');
    const selectedItems = Array.from(checkboxes).map(checkbox => checkbox.value);
    
    if (selectedItems.length === 0) {
      return;
    }
    
    if (confirm(`${selectedItems.length}件の項目をエクスポートしますか？`)) {
      // 現在のページのパスに基づいてルートを決定
      const currentPath = window.location.pathname;
      let exportRoute = '/bulk_export';
      
      if (currentPath.includes('/products')) {
        exportRoute = '/products/bulk_export';
      }
      
      this.submitForm(exportRoute, selectedItems);
    }
  }

  // フォーム送信
  submitForm(action, itemIds) {
    const form = document.createElement('form');
    form.method = 'POST';
    form.action = action;
    
    // CSRFトークンを追加
    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    const csrfInput = document.createElement('input');
    csrfInput.type = 'hidden';
    csrfInput.name = 'authenticity_token';
    csrfInput.value = csrfToken;
    form.appendChild(csrfInput);
    
    itemIds.forEach(itemId => {
      const input = document.createElement('input');
      input.type = 'hidden';
      input.name = 'item_ids[]';
      input.value = itemId;
      form.appendChild(input);
    });
    
    document.body.appendChild(form);
    form.submit();
  }
}

// 初期化
document.addEventListener('DOMContentLoaded', () => {
  new BulkActions();
}); 