require 'rails_helper'

RSpec.describe PatchesController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/patches').to route_to('patches#index')
    end

    it 'routes to #new' do
      expect(get: '/patch/new').to route_to('patches#new')
    end

    it 'routes to #show' do
      expect(get: 'user/hotlava69/patch/my-cool-patch')
        .to route_to(
          'patches#show',
          slug: 'my-cool-patch',
          user_username: 'hotlava69'
        )
      expect(get: '/patch/1').to route_to('patches#show', slug: '1')
    end

    it 'routes to #edit' do
      expect(get: '/patch/1/edit').to route_to('patches#edit', slug: '1')
    end

    it 'routes to #create' do
      expect(post: '/patch').to route_to('patches#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/patch/1').to route_to('patches#update', slug: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/patch/1').to route_to('patches#update', slug: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/patch/1').to route_to('patches#destroy', slug: '1')
    end
  end
end
