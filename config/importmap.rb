# Pin npm packages by running ./bin/importmap

pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin "application", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@nathanvda/cocoon", to: "https://ga.jspm.io/npm:@nathanvda/cocoon@1.2.14/cocoon.js"
pin "rails-ujs", to: "https://ga.jspm.io/npm:rails-ujs@5.2.8-1/lib/assets/compiled/rails-ujs.js"
