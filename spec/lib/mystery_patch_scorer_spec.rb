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
          worst_possible_score = solution[:attack] >= 63 ? 0 : 127
          error = (guess[:attack].to_i - solution[:attack].to_i).abs
          score = (1.0 - (error.to_f / (worst_possible_score - solution[:attack]).abs)) * 100.0
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

  context 'when delay feedback is zero' do
    let(:solution_overrides) do
      { delay_feedback: 0, delay_time: 45 }
    end

    let(:guess_overrides) do
      { delay_feedback: 0, delay_time: 0 }
    end

    let(:result) { scorer.score }

    it 'does not take delay time into account' do
      expect(result[:parameter_scores][:delay_time]).to be_nil
    end
  end

  context 'when the guess is perfectly correct' do
    let(:guess) { solution }

    it 'returns a total score of 100' do
      expect(scorer.score[:total_score]).to eq(100.0)
    end
  end

  context 'when worst possible answer is 100 points off' do
    let(:solution_overrides) do
      { peak: 27 } # Worst score is 127 = 100 points off
    end

    context 'when guess is 10 points off' do
      let(:guess_overrides) do
        { peak: 37 }
      end

      it 'returns accuract of 90 percent' do
        expect(scorer.score[:parameter_scores][:peak]).to(
           eq([27, 37, 10, 90.0])
        )
      end
    end

    context 'when guess is -10 points off' do
      let(:guess_overrides) do
        { peak: 17 }
      end

      it 'returns accuract of 90 percent' do
        expect(scorer.score[:parameter_scores][:peak]).to(
           eq([27, 17, 10, 90.0])
        )
      end
    end
  end

  context 'when voice is incorrect by any amount' do
    let(:solution_overrides) do
      { voice: 10 } # poly
    end
    let(:guess_overrides) do
      { voice: 30 } # unison
    end

    it 'reports 100% miss' do
      expect(scorer.score[:parameter_scores][:voice]).to(
         eq([10, 30, 127, 0.00])
      )
    end
  end
end
