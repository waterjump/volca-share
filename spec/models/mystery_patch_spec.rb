# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MysteryPatch, type: :model do
  let(:keys_patch) { create(:keys_patch) }

  describe 'validations' do
    subject { build(:mystery_patch) }

    it { is_expected.to validate_presence_of(:number) }
    it { is_expected.to validate_uniqueness_of(:number) }
  end

  describe 'callbacks' do
    it 'assigns a number on create' do
      record = build(:mystery_patch, number: nil)

      record.valid?

      expect(record.number).to eq(1)
    end

    it 'increments the number for each new record' do
      first_record = create(:mystery_patch)
      second_record = create(:mystery_patch)
      third_record = create(:mystery_patch)

      expect(first_record.number).to eq(1)
      expect(second_record.number).to eq(2)
      expect(third_record.number).to eq(3)
    end

    it 'does not overwrite an explicitly assigned number' do
      record = build(:mystery_patch, number: 42)

      record.valid?

      expect(record.number).to eq(42)
    end

    it 'uses the correct counter key' do
      expect(Counter).to(
        receive(:next!).with('mystery_patches.number').and_return(123)
      )

      record = build(:mystery_patch, number: nil)
      record.valid?

      expect(record.number).to eq(123)
    end
  end

  describe '.clone_from' do
    it 'creates a mystery patch from an existing keys patch' do
      mystery_patch = described_class.clone_from(keys_patch)

      expect(mystery_patch).to be_persisted
      expect(mystery_patch.id).not_to eq(keys_patch.id)
      expect(mystery_patch.cloned_from).to eq(keys_patch.id)

      expect(mystery_patch.voice).to eq(keys_patch.voice)
      expect(mystery_patch.detune).to eq(keys_patch.detune)
      expect(mystery_patch.portamento).to eq(keys_patch.portamento)
      expect(mystery_patch.vco_eg_int).to eq(keys_patch.vco_eg_int)
      expect(mystery_patch.cutoff).to eq(keys_patch.cutoff)
      expect(mystery_patch.peak).to eq(keys_patch.peak)
      expect(mystery_patch.vcf_eg_int).to eq(keys_patch.vcf_eg_int)
      expect(mystery_patch.lfo_rate).to eq(keys_patch.lfo_rate)
      expect(mystery_patch.lfo_pitch_int).to eq(keys_patch.lfo_pitch_int)
      expect(mystery_patch.lfo_cutoff_int).to eq(keys_patch.lfo_cutoff_int)
      expect(mystery_patch.attack).to eq(keys_patch.attack)
      expect(mystery_patch.decay_release).to eq(keys_patch.decay_release)
      expect(mystery_patch.sustain).to eq(keys_patch.sustain)
      expect(mystery_patch.delay_time).to eq(keys_patch.delay_time)
      expect(mystery_patch.delay_feedback).to eq(keys_patch.delay_feedback)
      expect(mystery_patch.lfo_shape).to eq(keys_patch.lfo_shape)
      expect(mystery_patch.lfo_trigger_sync).to eq(keys_patch.lfo_trigger_sync)
    end

    context 'when source patch is marked as secret (private)' do
      let(:keys_patch) { create(:user_keys_patch, secret: true) }

      it 'raises an error' do
        expect { described_class.clone_from(keys_patch) }.to(
          raise_error(MysteryPatch::SecretPatchCloneError)
        )
      end
    end
  end

  describe '.generate_random' do
    let!(:mystery_patch) do
      described_class.generate_random(overrides: overrides)
    end

    let(:overrides) do
      {}
    end

    it 'generates a random patch' do
      # Test with no overrides
      expect(described_class.generate_random).to be_valid
    end

    describe 'avoids completely closed filter' do
      context 'when the cutoff is below 30' do
        let(:overrides) do
          { cutoff: rand(30) }
        end

        it 'generates vcf eg int above 63' do
          expect(mystery_patch.vcf_eg_int).to be > 63
        end
      end
    end

    describe 'avoids VCF EG with inaudible effect' do
      context 'when the cutoff is above 90' do
        let(:overrides) do
          { cutoff: 90 + rand(38) }
        end

        it 'generates vcf eg int below 64' do
          expect(mystery_patch.vcf_eg_int).to be < 64
        end
      end
    end
  end

  describe '#random_param' do
    it 'is consistent with inputs' do
      generator = described_class

      n = 50_000
      zeros = n.times.count do
        generator.send(:random_param, **{preferred_weight: 5, total_weight: 6}) == 0
      end

      observed = zeros.to_f / n
      expected = (5.0 / 6.0) + (1.0 / 6.0) * (1.0 / 128.0)

      expect(observed).to be_within(0.01).of(expected)
    end
  end

  describe '#params_hash' do
    let(:mystery_patch) { described_class.clone_from(keys_patch) }
    it 'creates a hash from param fields' do
      hash = mystery_patch.params_hash
      expect(hash).to be_kind_of(String)
      expect(hash.size).to eq(64)
    end

    it 'changes if any of the params change' do
      hash_before = mystery_patch.params_hash
      if mystery_patch.attack < 127
        mystery_patch.attack += 1
      else
        mystery_patch.attack -= 1
      end
      hash_after = mystery_patch.params_hash

      expect(hash_before).not_to eq(hash_after)
    end
  end
end
