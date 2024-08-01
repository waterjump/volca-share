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
  get 'keys/emulator' => 'emulators#new_keys', as: :keys_emulator
  get 'synth_patch_namer' => 'synth_patch_namers#show'
  get 'synth_patch_name' => 'synth_patch_namers#name'
  post 'patch' => 'patches#create'
  resources :patches, only: [:index]
  get 'about' => 'welcome#index'
  resources :contacts, only: [:new, :create]
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

  unless Rails.application.config.consider_all_requests_local
    # Return 404 for all non-conforming paths
    get '*path', to: 'errors#not_found', via: :all
  end
end
