# frozen_string_literal: true

require 'rails_helper'

module Keys
  RSpec.describe 'Patch show', type: :request do
    describe 'GET /keys/patch/:id' do
      it 'accepts id as identifier' do
        patch = Patch.create!(attributes_for(:keys_patch))
        get keys_patch_path(patch.id)
        expect(response).to have_http_status(200)
      end
    end

    describe 'GET /user/:user_slug/keys/:slug' do
      it 'accepts slug as identifier' do
        user = create(:user)
        patch = Patch.create!(attributes_for(:keys_patch).merge(user: user))
        get user_keys_patch_path(user.slug, patch.slug)
        expect(response).to have_http_status(200)
      end
    end
  end
end
