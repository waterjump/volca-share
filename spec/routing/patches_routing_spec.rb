require 'rails_helper'

RSpec.describe PatchesController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/patches').to route_to('patches#index')
    end

    it 'routes to #new' do
      expect(get: '/patches/new').to route_to('patches#new')
    end

    it 'routes to #show' do
      expect(get: '/patches/1').to route_to('patches#show', id: '1')
    end

    it 'routes to #edit' do
      expect(get: '/patches/1/edit').to route_to('patches#edit', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/patches').to route_to('patches#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/patches/1').to route_to('patches#update', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/patches/1').to route_to('patches#update', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/patches/1').to route_to('patches#destroy', id: '1')
    end
  end
end
