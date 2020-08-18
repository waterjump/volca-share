# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Patches', type: :request do
  describe 'GET /patches' do
    it 'works! (now write some real specs)' do
      get patches_path
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET /user/user_slug/patch/patch_slug' do
    let(:user) { create(:user, username: 'realperson') }
    let!(:user_patch) { create(:patch, user: user) }

    context 'when username slug matches patch slug' do
      it 'returns 200' do
        get "/user/#{user.slug}/patch/#{user_patch.slug}"

        expect(response).to have_http_status(200)
      end
    end

    context 'when username slug does not match patch slug' do
      it 'returns 404' do
        fake_user_slug = 'foo6969'

        get "/user/#{fake_user_slug}/patch/#{user_patch.slug}"

        expect(response).to have_http_status(404)
      end
    end
  end
end
