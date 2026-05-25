// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/stimulus"
import "controllers"
import "@nathanvda/cocoon"
import "rails-ujs"

// Bootstrapの初期化関数
function initializeBootstrap() {
  cleanupOrphanedBackdrops()

  // Bootstrapのツールチップを初期化
  const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]')
  tooltipTriggerList.forEach(tooltipTriggerEl => {
    new bootstrap.Tooltip(tooltipTriggerEl)
  })

  // Bootstrapのポップオーバーを初期化
  const popoverTriggerList = document.querySelectorAll('[data-bs-toggle="popover"]')
  popoverTriggerList.forEach(popoverTriggerEl => {
    new bootstrap.Popover(popoverTriggerEl)
  })

  // Bootstrapのドロップダウンを初期化
  const dropdownElementList = document.querySelectorAll('.dropdown-toggle')
  dropdownElementList.forEach(dropdownToggleEl => {
    new bootstrap.Dropdown(dropdownToggleEl)
  })
}

function cleanupOrphanedBackdrops() {
  const activeModal = document.querySelector('.modal.show')
  const activeOffcanvas = document.querySelector('.offcanvas.show')

  if (activeModal || activeOffcanvas) {
    return
  }

  document.querySelectorAll('.modal-backdrop, .offcanvas-backdrop').forEach(backdrop => {
    backdrop.remove()
  })
  document.body.classList.remove('modal-open')
  document.body.classList.remove('offcanvas-backdrop')
  document.body.style.removeProperty('overflow')
  document.body.style.removeProperty('padding-right')
}

// 即座に実行（既にDOMが読み込まれている場合）
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeBootstrap)
} else {
  initializeBootstrap()
}
