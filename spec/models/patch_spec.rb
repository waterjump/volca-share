# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Patch  do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_uniqueness_of(:slug) }
    it { is_expected.to validate_numericality_of(:attack) }
    it { is_expected.to validate_numericality_of(:decay_release) }
    it { is_expected.to validate_numericality_of(:cutoff_eg_int) }
    it { is_expected.to validate_numericality_of(:peak) }
    it { is_expected.to validate_numericality_of(:cutoff) }
    it { is_expected.to validate_numericality_of(:lfo_rate) }
    it { is_expected.to validate_numericality_of(:lfo_int) }
    it { is_expected.to validate_numericality_of(:vco1_pitch) }
    it { is_expected.to validate_numericality_of(:vco2_pitch) }
    it { is_expected.to validate_numericality_of(:vco3_pitch) }
    it do
      is_expected.to(
        custom_validate(:audio_sample).with_validator(AudioSampleValidator)
      )
    end

    describe '#patch_is_not_default' do
      context 'when all patch synth paramaters are default' do
        it 'marks the patch as invalid' do
          default_patch =
            FactoryBot.build(
              :patch,
              attack: 63,
              decay_release: 63,
              cutoff_eg_int: 63,
              octave: 63,
              peak: 63,
              cutoff: 63,
              lfo_rate: 63,
              lfo_int: 63,
              vco1_pitch: 63,
              vco1_active: true,
              vco2_pitch: 63,
              vco2_active: true,
              vco3_pitch: 63,
              vco3_active: true,
              vco_group: 'three',
              lfo_target_amp: false,
              lfo_target_pitch: false,
              lfo_target_cutoff: true,
              lfo_wave: false,
              vco1_wave: false,
              vco2_wave: false,
              vco3_wave: true,
              sustain_on: false,
              amp_eg_on: false
            )
          expect(default_patch).to be_invalid
        end
      end

      context 'when patch is not default' do
        it 'validates the patch' do
          non_default_patch = FactoryBot.build(:patch, peak: 69)
          expect(non_default_patch).to be_valid
        end
      end
    end

    context 'when audio_sample is nil' do
      it 'sets that audio_sample_available to nil' do
        patch = create(:patch, audio_sample: nil, audio_sample_available: true)
        expect(patch.audio_sample_available).to be_nil
      end
    end

    context 'when audio_sample is not nil' do
      it 'validates that audio_sample_available is true' do
        patch = build(
          :user_patch,
          audio_sample: 'https://soundcloud.com/squidbrain/fake-track'
        )

        expect(patch).not_to be_valid
        expect(patch.errors.full_messages).to eq(['Audio sample is not available.'])
      end
    end
  end

  describe 'fields' do
    it do
      is_expected.to(
        have_field(:audio_sample_available)
          .of_type(Mongoid::Boolean)
          .with_default_value_of(nil)
      )
    end
  end

  describe 'quality' do
    context 'when a legacy record has audio_sample that is no longer available' do
      it 'has less quality than the same patch with available audio sample' do
        legacy_patch = create(:user_patch).tap do |patch|
          patch.audio_sample_available = false
          patch.save(validate: false)
        end

        patch_with_available_audio_sample = create(:user_patch)

        expect(legacy_patch.quality).to(
          be < patch_with_available_audio_sample.quality
        )
      end
    end
  end

  describe '#persist_quality' do
    it 'persists quality as database field' do
      patch = FactoryBot.create(:patch)
      patch.update!(quality: nil)
      patch.persist_quality
      expect(patch.read_attribute(:quality)).to be_present
    end

    it 'updates quality value when patch is updated' do
      patch = FactoryBot.create(:patch)
      initial_quality = patch.quality
      patch.update!(notes: '', audio_sample: nil)

      expect(patch.read_attribute(:quality)).to be < initial_quality
    end
  end
end
