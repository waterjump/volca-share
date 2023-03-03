# frozen_string_literal: true

require 'rails_helper'

shared_examples_for 'models with audio_sample field' do
  # TODO: Write tests for user-only validation (lib/audio_sample_validator.rb)
  context 'when audio_sample is nil' do
    let(:audio_sample) { nil }

    it 'sets that audio_sample_available to nil' do
      expect(model.audio_sample_available).to be_nil
    end
  end

  context 'when audio_sample is not nil' do
    let(:audio_sample) { 'https://soundcloud.com/squidbrain/fake-track' }

    context 'when remote audio sample is unavailable' do
      it 'is not valid' do
        expect(user_model).not_to be_valid
        expect(user_model.errors.full_messages).to eq(['Audio sample is not available.'])
      end
    end

    context 'when remote audio sample is available' do
      let(:audio_sample) { 'https://soundcloud.com/69bot/shallow' }

      it 'is valid' do
        expect(user_model).to be_valid
        expect(user_model.audio_sample_available).to be true
      end
    end

    context 'when url format is invalid' do
      let(:audio_sample) { 'https://foo.edu/69bot/fake-shallow' }

      it 'is not valid' do
        expect(user_model).not_to be_valid
        expect(user_model.errors.full_messages).to include(
          'Audio sample needs to be direct SoundCloud, Freesound or YouTube link.'
        )
      end
    end
  end
end

