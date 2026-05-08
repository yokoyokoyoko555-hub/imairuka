// 削除ボタン用のJavaScript
document.addEventListener('DOMContentLoaded', function() {
  // 削除ボタンのイベントリスナーを設定
  const deleteButtons = document.querySelectorAll('[data-delete-action]');
  
  deleteButtons.forEach(button => {
    button.addEventListener('click', function(e) {
      e.preventDefault();
      
      const url = this.getAttribute('href');
      const confirmMessage = this.getAttribute('data-confirm') || '本当に削除しますか？';
      
      if (confirm(confirmMessage)) {
        // フォームを作成してPOSTリクエストを送信
        const form = document.createElement('form');
        form.method = 'POST';
        form.action = url;
        
        // CSRFトークンを追加
        const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
        const csrfInput = document.createElement('input');
        csrfInput.type = 'hidden';
        csrfInput.name = 'authenticity_token';
        csrfInput.value = csrfToken;
        form.appendChild(csrfInput);
        
        // _methodをDELETEに設定
        const methodInput = document.createElement('input');
        methodInput.type = 'hidden';
        methodInput.name = '_method';
        methodInput.value = 'DELETE';
        form.appendChild(methodInput);
        
        document.body.appendChild(form);
        form.submit();
      }
    });
  });
}); 