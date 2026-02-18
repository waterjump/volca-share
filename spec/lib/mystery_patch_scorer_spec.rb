# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MysteryPatchScorer do
  let(:scorer) { described_class.new(solution, guess) }

  let(:solution) do
    VolcaShare::Keys::PatchViewModel
      .wrap(create(:keys_patch))
      .emulator_query_string
      .except(:octave)
      .merge(solution_overrides)
  end

  let(:guess) do
    VolcaShare::Keys::PatchViewModel
      .wrap(create(:keys_patch))
      .emulator_query_string
      .except(:octave)
      .merge(guess_overrides)
  end

  let(:solution_overrides) { {} }
  let(:guess_overrides) { {} }

  it 'returns a hash with results' do
    expect(scorer.score).to be_a(Hash)
    expect(scorer.score).to have_key(:total_score)
  end

  it 'returns an score for each parameter' do
    result = scorer.score
    expect(result).to have_key(:parameter_scores)
    expect(result[:parameter_scores]).to be_a(Hash)
    solution.each_key do |param|
      expect(result[:parameter_scores]).to have_key(param)
    end

    expect(result[:parameter_scores][:octave]).to be_nil

    expect(result[:parameter_scores][:attack]).to eq(
      [
        solution[:attack],
        guess[:attack],
        (solution[:attack].to_i - guess[:attack].to_i).abs,
        begin
          worst_possible_score = 63 + (solution[:attack] - 63).abs
          error = (guess[:attack].to_i - solution[:attack].to_i).abs
          score = ((worst_possible_score - error).abs / worst_possible_score.to_f) * 100.0
          score.round(2)
        end
      ]
    )
  end

  context 'when LFO is not applied' do
    let(:solution_overrides) do
      { lfo_pitch_int: 0, lfo_cutoff_int: 0, lfo_shape: 'square' }
    end
    let(:guess_overrides) do
      { lfo_pitch_int: 0, lfo_cutoff_int: 0, lfo_shape: 'triangle' }
    end

    let(:result) { scorer.score }

    it 'does not take LFO shape into account' do
      expect(result[:parameter_scores][:lfo_shape]).to be_nil
    end

    it 'does not take lfo_trigger_sync into account' do
      expect(result[:parameter_scores][:lfo_trigger_sync]).to be_nil
    end

    it 'does not take lfo_rate into account' do
      expect(result[:parameter_scores][:lfo_rate]).to be_nil
    end
  end

  context 'when the guess is perfectly correct' do
    let(:guess) { solution }

    it 'returns a total score of 100' do
      expect(scorer.score[:total_score]).to eq(100)
    end
  end

  context 'when the guess is off by 10 for a numeric parameter' do
    let(:guess) do
      solution.merge(cutoff: (solution[:cutoff] + 10))
    end

    it 'returns a total score less than 100' do
      expect(scorer.score[:total_score]).to be < 100
    end
  end
end
