# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Patch, 'validations' do
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

    it 'updates quality for all patches' do
      old_patch = nil
      Timecop.freeze(6.months.ago) do
        old_patch = FactoryBot.create(:patch)
        expect(old_patch.quality).to be > 1
      end
      new_patch = FactoryBot.create(:patch)
      old_patch.reload
      expect(old_patch.quality).to be < 0.001
    end
  end
end
