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

    describe 'getting a user patch by patch id' do
      let(:user_patch) { create(:user_keys_patch) }
      before { get "/keys/patch/#{user_patch.id}" }

      it 'redirects to path that uses slugs' do
        expect(response.location).to(
          include(user_keys_patch_path(user_patch.user.slug, user_patch.slug))
        )
      end

      it 'has a 301 Moved Permanently status' do
        expect(response.status).to eq(301)
      end
    end

    describe 'GET /mystery_patch' do
      before do
        # create mystery patch
        create(:keys_patch)
      end

      context 'when calling in html format' do
        it 'shows gameplay page' do
          get '/mystery_patch'

          expect(response.location).to include('/mystery_patch')
          expect(response).to have_http_status(200)
        end
      end

      context 'when calling in json format' do
        it 'responds with a mystery patch' do
          get '/mystery_patch.json'

          expect(response).to have_http_status(200)
          expect(JSON.parse(response.body)).to have_key('patch')
        end
      end
    end

    describe 'POST /mystery_patch' do
      let!(:mystery_patch) { create(:keys_patch) }
      let(:params) do
        {
          patch: {
            detune: 0, portamento: 0, voice: 30, attack: 0, decay_release: 0,
            cutoff: 127, lfo_trigger_sync: false, peak: 0, lfo_rate: 0,
            vco_eg_int: 0, vcf_eg_int: 0, lfo_pitch_int: 0, lfo_cutoff_int: 0,
            delay_time: 0, delay_feedback: 0, lfo_shape: 'triangle', step_trigger: true,
            sustain: 127
          }
        }
      end

      it 'response with a dummy message' do
        post '/mystery_patch.json', params: params

        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)).to(
          include({ 'message' => 'Score submitted' })
        )
      end
    end
  end
end
