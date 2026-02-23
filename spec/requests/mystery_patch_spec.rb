# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Mystery Patch requests', type: :request do
  describe 'GET /mystery_patch' do
    before do
      MysteryPatch.clone_from(build(:keys_patch))
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
        body = JSON.parse(response.body)
        expect(body).to have_key('patch')
        expect(body).to have_key('digest')
      end
    end
  end

  describe 'POST /mystery_patch' do
    let!(:mystery_patch) { MysteryPatch.clone_from(build(:keys_patch)) }
    let(:id) { mystery_patch.id }
    let(:digest) { mystery_patch.params_hash }
    let(:params) do
      {
        id: id,
        digest: digest,
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

    context 'when id is not found' do
      let(:id) { 'some_unfound_id' }

      it 'returns 404 not found' do
        post '/mystery_patch.json', params: params

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when hash does not match' do
      let(:digest) { 'some_other_hash' }

      it 'returns 400 bad request' do
        post '/mystery_patch.json', params: params

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
