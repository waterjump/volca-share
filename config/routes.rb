Rails.application.routes.draw do
  user_options =
    {
      only: [:show],
      param: :slug,
      controller: 'users',
      constraints: { slug: /[A-Za-z0-9\-\_]*/ }
    }

  devise_for :users, controllers: { registrations: 'users/registrations' }
  resources :user, user_options do
    resources :patch, only: [:show], param: :slug, controller: 'patches'
  end

  resources :patch, param: :slug, controller: 'patches', except: [:index]
  post 'patch' => 'patches#create'
  resources :patches, only: [:index]
  get 'welcome/index'
  match 'tags/show' => 'tags#show', via: :get
  match 'oembed' => 'patches#oembed', via: :get

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'patches#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
