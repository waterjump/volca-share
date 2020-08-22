# frozen_string_literal: true

Rails.application.routes.draw do
  match '/404', to: 'errors#not_found', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all

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
              only: [:show, :edit],
              param: :slug,
              controller: 'keys/patches',
              path: 'keys/patch'
  end

  resources :patch, param: :id, controller: 'patches', except: [:index]
  get 'bass/emulator' => 'emulators#new', as: :bass_emulator
  post 'patch' => 'patches#create'
  resources :patches, only: [:index]
  get 'about' => 'welcome#index'
  match 'tags/show' => 'tags#show', via: :get
  match 'oembed' => 'patches#oembed', via: :get

  namespace 'keys' do
    resources :patch,
              controller: 'patches',
              only: [:new, :show, :update, :destroy],
              param: :id
    resources :patches, only: [:index]
    post 'patch' => 'patches#create'
    match 'tags/show' => 'tags#show', via: :get
    match 'oembed' => 'patches#oembed', via: :get
  end

  root 'welcome#index'
end
