# frozen_string_literal: true

class MysteryPatchScorer
  LFO_UNAPPLIED_PARAMS = %i(lfo_shape lfo_trigger_sync lfo_rate).freeze

  def initialize(solution, guess)
    @solution = solution
    @guess = guess
    @parameter_scores = calculate_parameter_scores
  end

  def score
    {
      total_score: calculate_total_score,
      parameter_scores: calculate_parameter_scores
    }
  end

  private

  attr_reader :solution, :guess, :parameter_scores

  def calculate_total_score
    worst_possible_score = 0
    total_error = 0
    parameter_scores.each do |param, (actual, guess, error, accuracy)|
      if actual.is_a?(Numeric)
        worst_possible_score += 63 + (actual - 63).abs
      else
        worst_possible_score += 127
      end
      total_error += error
    end

    # Convert total error to a score out of 100
    score = ((worst_possible_score - total_error).abs / worst_possible_score.to_f) * 100.0

    score.round(2)
  end

  def calculate_parameter_scores
    solution.except(:octave).each_with_object({}) do |(param, value), scores|

      next if LFO_UNAPPLIED_PARAMS.include?(param) && solution[:lfo_pitch_int] == 0 && solution[:lfo_cutoff_int] == 0

      if value.is_a?(Numeric)
        worst_possible_score = 63 + (value - 63).abs
        error = (guess[param].to_i - value.to_i).abs
        score = ((worst_possible_score - error).abs / worst_possible_score.to_f) * 100.0
        scores[param] = [value, guess[param], error, score.round(2)]
      else
        score = guess[param].to_s == value.to_s ? 100.0 : 0.0
        scores[param] = [value, guess[param], score == 100.0 ? 0 : 127, score]
      end
    end
  end
end
