# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Keys::Patch do
  describe 'fields' do
    it { is_expected.to have_field(:name).of_type(String) }

    it do
      is_expected.to(
        have_field(:secret)
          .of_type(Mongoid::Boolean)
          .with_default_value_of(false)
      )
    end

    it { is_expected.to have_field(:notes).of_type(String) }
    it { is_expected.to have_field(:slug).of_type(String) }

    it do
      is_expected.to(
        have_field(:voice).of_type(Integer).with_default_value_of(70)
      )
    end

    it do
      is_expected.to(
        have_field(:octave).of_type(Integer).with_default_value_of(70)
      )
    end

    it do
      is_expected.to(
        have_field(:detune).of_type(Integer).with_default_value_of(0)
      )
    end

    it do
      is_expected.to(
        have_field(:portamento).of_type(Integer).with_default_value_of(0)
      )
    end

    it do
      is_expected.to(
        have_field(:vco_eg_int).of_type(Integer).with_default_value_of(0)
      )
    end

    it do
      is_expected.to(
        have_field(:cutoff).of_type(Integer).with_default_value_of(63)
      )
    end

    it do
      is_expected.to(
        have_field(:peak).of_type(Integer).with_default_value_of(0)
      )
    end

    it do
      is_expected.to(
        have_field(:vcf_eg_int).of_type(Integer).with_default_value_of(0)
      )
    end

    it do
      is_expected.to(
        have_field(:lfo_rate).of_type(Integer).with_default_value_of(0)
      )
    end

    it do
      is_expected.to(
        have_field(:lfo_pitch_int).of_type(Integer).with_default_value_of(0)
      )
    end

    it do
      is_expected.to(
        have_field(:lfo_cutoff_int).of_type(Integer).with_default_value_of(0)
      )
    end

    it do
      is_expected.to(
        have_field(:attack).of_type(Integer).with_default_value_of(0)
      )
    end

    it do
      is_expected.to(
        have_field(:decay_release).of_type(Integer).with_default_value_of(63)
      )
    end

    it do
      is_expected.to(
        have_field(:sustain).of_type(Integer).with_default_value_of(127)
      )
    end

    it do
      is_expected.to(
        have_field(:delay_time).of_type(Integer).with_default_value_of(0)
      )
    end

    it do
      is_expected.to(
        have_field(:delay_feedback).of_type(Integer).with_default_value_of(0)
      )
    end

    it do
      is_expected.to(
        have_field(:lfo_shape).of_type(String).with_default_value_of('triangle')
      )
    end

    it do
      is_expected.to(
        have_field(:lfo_trigger_sync)
          .of_type(Mongoid::Boolean)
          .with_default_value_of(false)
      )
    end

    it do
      is_expected.to(
        have_field(:step_trigger)
          .of_type(Mongoid::Boolean)
          .with_default_value_of(false)
      )
    end

    it do
      is_expected.to(
        have_field(:tempo_delay)
          .of_type(Mongoid::Boolean)
          .with_default_value_of(true)
      )
    end

    it do
      is_expected.to(
        have_field(:audio_sample)
          .of_type(String)
          .with_default_value_of(nil)
      )
    end

    it do
      is_expected.to(
        have_field(:audio_sample_available)
          .of_type(Mongoid::Boolean)
          .with_default_value_of(nil)
      )
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:slug) }

    it do
      is_expected.to validate_inclusion_of(:voice).to_allow(10, 30, 50, 70, 100, 120)
    end

    it do
      is_expected.to(
        validate_inclusion_of(:octave).to_allow(10, 30, 50, 70, 100, 120)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:detune)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:portamento)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:vco_eg_int)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:cutoff)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:peak)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:vcf_eg_int)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:lfo_rate)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:lfo_pitch_int)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:lfo_cutoff_int)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:attack)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:decay_release)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:sustain)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:delay_time)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_numericality_of(:delay_feedback)
          .greater_than_or_equal_to(0)
          .less_than_or_equal_to(127)
      )
    end

    it do
      is_expected.to(
        validate_inclusion_of(:lfo_shape).to_allow('saw', 'triangle', 'square')
      )
    end

    it do
      is_expected.to(
        custom_validate(:audio_sample).with_validator(AudioSampleValidator)
      )
    end

    context 'when patch is all default values' do
      it 'is not valid' do
        default_patch =
          FactoryBot.build(
            :keys_patch,
            voice: 70,
            octave: 70,
            detune: 0,
            portamento: 0,
            vco_eg_int: 0,
            cutoff: 63,
            peak: 0,
            vcf_eg_int: 0,
            lfo_rate: 0,
            lfo_pitch_int: 0,
            lfo_cutoff_int: 0,
            attack: 0,
            decay_release: 63,
            sustain: 127,
            delay_time: 0,
            delay_feedback: 0,
            lfo_shape: 'triangle',
            lfo_trigger_sync: false,
            step_trigger: false,
            tempo_delay: true
          )
        expect(default_patch).to be_invalid
      end
    end

    context 'when patch is not all default values' do
      it 'is valid' do
        non_default_patch = FactoryBot.build(:keys_patch, peak: 69)
        expect(non_default_patch).to be_valid
      end
    end

    context 'when audio_sample is nil' do
      it 'sets that audio_sample_available to nil' do
        patch = create(:keys_patch, audio_sample: nil, audio_sample_available: true)
        expect(patch.audio_sample_available).to be_nil
      end
    end

    context 'when audio_sample is not nil' do
      it 'validates that audio_sample_available is true' do
        patch = build(
          :keys_patch,
          audio_sample: 'https://soundcloud.com/squidbrain/fake-track'
        )

        expect(patch).not_to be_valid
        expect(patch.errors.full_messages).to eq(['Audio sample is not available.'])
      end
    end
  end

  describe 'quality' do
    context 'when a legacy record has audio_sample that is no longer available' do
      it 'has less quality than the same patch with available audio sample' do
        legacy_patch = create(:keys_patch).tap do |patch|
          patch.audio_sample_available = false
          patch.save(validate: false)
        end

        patch_with_available_audio_sample = create(:keys_patch)

        expect(legacy_patch.quality).to(
          be < patch_with_available_audio_sample.quality
        )
      end
    end
  end

  describe '#persist_quality' do
    it 'persists quality as database field' do
      patch = create(:keys_patch)
      patch.update!(quality: nil)
      patch.persist_quality
      expect(patch.read_attribute(:quality)).to be_present
    end

    it 'updates quality value when patch is updated' do
      patch = create(:keys_patch)
      initial_quality = patch.quality
      patch.update!(notes: '', audio_sample: nil)

      expect(patch.read_attribute(:quality)).to be < initial_quality
    end
  end
end
