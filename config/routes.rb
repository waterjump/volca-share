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
    resources :patch, only: [:show], param: :slug, controller: 'patches' do
      member do
        get :emulation
      end
    end
    resources :keys_patch,
              only: [:show, :edit],
              param: :slug,
              controller: 'keys/patches',
              path: 'keys/patch' do
      member do
        get :emulation
      end
    end
  end

  resources :patch, param: :id, controller: 'patches', except: [:index] do
    member do
      get :emulation
    end
  end
  get 'bass/emulator' => 'emulators#new', as: :bass_emulator
  get 'keys/emulator' => 'emulators#new_keys', as: :keys_emulator
  get 'synth_patch_namer' => 'synth_patch_namers#show'
  get 'synth_patch_name' => 'synth_patch_namers#name'
  post 'patch' => 'patches#create'
  resources :patches, only: [:index]
  get 'about' => 'welcome#index'
  match 'tags/show' => 'tags#show', via: :get
  match 'oembed' => 'patches#oembed', via: :get

  get 'mystery_patch' => 'mystery_patches#mystery_patch'
  post 'mystery_patch' => 'mystery_patches#submit_mystery_patch'
  post 'mystery_patch_hint' => 'mystery_patches#hint'
  get 'sandbox/poc' => 'sandbox#poc'

  namespace 'keys' do
    resources :patch,
              controller: 'patches',
              only: [:new, :show, :update, :destroy],
              param: :id do
      member do
        get :emulation
      end
    end
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
