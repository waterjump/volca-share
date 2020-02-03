# frozen_string_literal: true

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
    resources :keys_patch,
              only: [:show],
              param: :slug,
              controller: 'keys/patches',
              path: 'keys'
  end

  resources :patch, param: :slug, controller: 'patches', except: [:index]
  post 'patch' => 'patches#create'
  resources :patches, only: [:index]
  get 'about' => 'welcome#index'
  match 'tags/show' => 'tags#show', via: :get
  match 'oembed' => 'patches#oembed', via: :get

  namespace 'keys' do
    resources :patch, controller: 'patches', only: [:new, :show]
    post 'patch' => 'patches#create'
  end

  root 'patches#new'
end
