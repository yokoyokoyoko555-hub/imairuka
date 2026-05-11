Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root 'dashboard#index'

  # 案件管理
  resources :orders do
    collection do
      get :export
      post :import
      get :billing
      post :bulk_delete
    end
    member do
      get :show_billing
      get :edit_payment
      patch :update_payment
      get :print
      get :preview
      get :edit_delivery
      get :edit_billing
      get :preview_delivery
      get :preview_billing
      get :preview_receipt
      get :print_delivery
      get :print_receipt
      post :checkout
    end
  end

  # 顧客管理
  resources :customers do
    collection do
      post :bulk_delete
    end
  end

  # 商品管理
  resources :products do
    collection do
      get :export
      post :bulk_delete
    end
    member do
      get :info
    end
  end

  # ヘルスチェック
  get 'health_check', to: 'health_check#index'

  # 決済管理
  resources :payment_histories, only: [:index]

  namespace :admin do
    resources :companies, only: [:index, :show, :new, :create] do
      resources :user_invitations, path: :invitations, only: [:new, :create]
    end
  end

  namespace :account do
    resources :users, only: [:index]
    resources :user_invitations, path: :invitations, only: [:new, :create]
  end

  get 'invitations/:token', to: 'invitation_acceptances#show', as: :invitation
  post 'invitations/:token/accept', to: 'invitation_acceptances#accept', as: :accept_invitation

  # Stripe Connect
  post 'stripe_connect', to: 'stripe_connect#create'
  get 'stripe_connect/refresh', to: 'stripe_connect#refresh', as: :stripe_connect_refresh
  get 'stripe_connect/callback', to: 'stripe_connect#callback', as: :stripe_connect_callback
  post 'stripe/webhook', to: 'stripe_webhooks#create'

  # 設定
  resources :settings, only: [:index, :update], path: 'settings', as: 'settings' do
    collection do
      patch :update
    end
  end

  namespace :settings do
    get 'company', to: 'settings#company'
    patch 'company', to: 'settings#update_company', as: :update_company
  end

  # セッション管理（ログイン）
  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'

  # 文書管理
  resources :quotations do
    collection do
      get :export
      post :import
      get :print
      get :search_products
      get :download_pdf
    end
    member do
      get :print
      get :download_pdf
      get :copy_to_delivery_note
      get :copy_to_invoice
      get :copy_to_receipt
    end
  end

  # 納品書管理
  resources :delivery_notes do
    collection do
      get :export
      post :import
      get :print
      get :search_products
      get :download_pdf
    end
    member do
      get :print
      get :download_pdf
    end
  end

  # 請求書管理
  resources :invoices do
    collection do
      get :export
      post :import
      post :bulk_delete
      get :print
      get :search_products
      get :download_pdf
    end
    member do
      get :print
      get :print_tax_invoice
      get :download_pdf
    end
  end

  # 領収書管理
  resources :receipts do
    collection do
      get :export
      post :import
      get :print
      get :search_products
      get :download_pdf
    end
    member do
      get :print
      get :download_pdf
    end
  end

  # 案件ステータス管理
  resources :order_statuses

  # Stripe決済関連
  get '/cancel', to: 'orders#cancel'
  get '/success', to: 'orders#success'
end
