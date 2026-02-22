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
        expect(JSON.parse(response.body)).to have_key('patch')
      end
    end
  end

  describe 'POST /mystery_patch' do
    let!(:mystery_patch) { MysteryPatch.clone_from(build(:keys_patch)) }
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
