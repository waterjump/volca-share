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

  describe 'POST /mystery_patch_hint' do
    let!(:mystery_patch) do
      create(
        :mystery_patch,
        attack: 127,
        peak: 126,
        cutoff: 12
      )
    end
    let(:params) do
      {
        mysteryPatchId: mystery_patch.id.to_s,
        patch: {
          detune: mystery_patch.detune,
          portamento: mystery_patch.portamento,
          voice: mystery_patch.voice,
          attack: 0,
          decay_release: mystery_patch.decay_release,
          cutoff: 127,
          lfo_trigger_sync: mystery_patch.lfo_trigger_sync,
          peak: 0,
          lfo_rate: mystery_patch.lfo_rate,
          vco_eg_int: mystery_patch.vco_eg_int,
          vcf_eg_int: mystery_patch.vcf_eg_int,
          lfo_pitch_int: mystery_patch.lfo_pitch_int,
          lfo_cutoff_int: mystery_patch.lfo_cutoff_int,
          delay_time: mystery_patch.delay_time,
          delay_feedback: mystery_patch.delay_feedback,
          lfo_shape: mystery_patch.lfo_shape,
          step_trigger: mystery_patch.step_trigger,
          sustain: mystery_patch.sustain
        }
      }
    end

    it 'returns the two furthest-off parameter names' do
      post '/mystery_patch_hint.json', params: params

      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)).to include(
        'hint_params' => %w[attack peak],
        'hints_used' => 1,
        'hints_remaining' => 1
      )
    end

    it 'refuses a third hint request for the same game' do
      2.times do
        post '/mystery_patch_hint.json', params: params
        expect(response).to have_http_status(200)
      end

      post '/mystery_patch_hint.json', params: params

      expect(response).to have_http_status(:too_many_requests)
      expect(JSON.parse(response.body)).to include(
        'message' => 'Hint limit reached'
      )
    end

    context 'when id is not found' do
      it 'returns 404 not found' do
        post '/mystery_patch_hint.json', params: params.merge(mysteryPatchId: 'some_unfound_id')

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
