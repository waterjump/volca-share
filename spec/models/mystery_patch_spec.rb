# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MysteryPatch, type: :model do
  let(:keys_patch) { create(:keys_patch) }

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
