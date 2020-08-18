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

    describe 'GET /user/:user_slug/keys/patch/:slug' do
      let(:user) { create(:user, username: 'realperson') }
      let!(:user_patch) { create(:user_keys_patch, user: user) }

      context 'when username slug matches patch slug' do
        it 'returns 200' do
          get "/user/#{user.slug}/keys/patch/#{user_patch.slug}"

          expect(response).to have_http_status(200)
        end
      end

      context 'when username slug does not match patch slug' do
        it 'returns 404' do
          fake_user_slug = 'foo6969'

          get "/user/#{fake_user_slug}/keys/patch/#{user_patch.slug}"

          expect(response).to have_http_status(404)
        end
      end
    end
  end
end
