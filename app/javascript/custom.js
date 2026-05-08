document.addEventListener('turbo:load', function() {
  // サイドバーのトグル機能
  const toggleSidebar = () => {
    document.getElementById('sidebar').classList.toggle('active');
    document.getElementById('content').classList.toggle('active');
  };

  // ナビゲーションバーのトグルボタンにイベントリスナーを追加
  const navbarToggler = document.querySelector('.navbar-toggler');
  if (navbarToggler) {
    navbarToggler.addEventListener('click', toggleSidebar);
  }

  // アクティブなメニュー項目のハイライト
  const currentPath = window.location.pathname;
  const menuItems = document.querySelectorAll('#sidebar .nav-link');
  menuItems.forEach(item => {
    if (item.getAttribute('href') === currentPath) {
      item.parentElement.classList.add('active');
    }
  });

  // 一括選択機能
  const selectAllCheckbox = document.querySelector('#select_all');
  if (selectAllCheckbox) {
    selectAllCheckbox.addEventListener('change', function() {
      const checkboxes = document.querySelectorAll('input[name="order_ids[]"]');
      checkboxes.forEach(checkbox => {
        checkbox.checked = this.checked;
      });
    });
  }

  // 個別チェックボックスの変更時に全選択チェックボックスの状態を更新
  const orderCheckboxes = document.querySelectorAll('input[name="order_ids[]"]');
  if (orderCheckboxes.length > 0) {
    orderCheckboxes.forEach(checkbox => {
      checkbox.addEventListener('change', function() {
        const selectAllCheckbox = document.querySelector('#select_all');
        const checkedBoxes = document.querySelectorAll('input[name="order_ids[]"]:checked');
        selectAllCheckbox.checked = checkedBoxes.length === orderCheckboxes.length;
      });
    });
  }
}); 