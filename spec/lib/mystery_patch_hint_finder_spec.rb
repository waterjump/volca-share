# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MysteryPatchHintFinder do
  subject(:hint_params) do
    described_class.new(
      mystery_patch: mystery_patch,
      guess: guess
    ).hint_params
  end

  let(:mystery_patch) do
    create(
      :mystery_patch,
      attack: 120,
      cutoff: 40,
      peak: 90,
      lfo_pitch_int: 0,
      lfo_cutoff_int: 0,
      lfo_shape: 'square',
      lfo_trigger_sync: true,
      delay_feedback: 0,
      delay_time: 100
    )
  end

  let(:guess) do
    {
      voice: mystery_patch.voice,
      detune: mystery_patch.detune,
      portamento: mystery_patch.portamento,
      vco_eg_int: mystery_patch.vco_eg_int,
      cutoff: 0,
      peak: 0,
      vcf_eg_int: mystery_patch.vcf_eg_int,
      lfo_rate: 127,
      lfo_pitch_int: 0,
      lfo_cutoff_int: 0,
      attack: 0,
      decay_release: mystery_patch.decay_release,
      sustain: mystery_patch.sustain,
      delay_time: 0,
      delay_feedback: 0,
      lfo_shape: 'triangle',
      lfo_trigger_sync: false,
      step_trigger: false
    }
  end

  it 'returns the two furthest-off scoring parameters' do
    expect(hint_params).to eq(%i[attack peak])
  end

  it 'breaks ties alphabetically by parameter name' do
    equal_guess = guess.merge(attack: 20, cutoff: 60, peak: mystery_patch.peak)

    result = described_class.new(
      mystery_patch: mystery_patch,
      guess: equal_guess
    ).hint_params

    expect(result).to eq(%i[attack cutoff])
  end

  it 'does not include parameters ignored by scoring rules' do
    expect(hint_params).not_to include(:lfo_shape, :lfo_trigger_sync, :lfo_rate, :delay_time)
  end
end
