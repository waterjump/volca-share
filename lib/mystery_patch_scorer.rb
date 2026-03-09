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
    biggest_possible_error = 0
    total_error = 0

    parameter_scores.each do |param, (actual, guess, error, accuracy)|
      if actual.is_a?(Numeric) && param != :voice
        biggest_possible_error += 63 + (actual - 63).abs
      else
        biggest_possible_error += 127
      end
      total_error += error
    end

    # Convert total error to a score out of 100
    score = (
      (biggest_possible_error - total_error).abs /
      biggest_possible_error.to_f
    ) * 100.0

    score.round(2)
  end

  def calculate_parameter_scores
    solution.except(:octave).each_with_object({}) do |(param, value), scores|
      skip_lfo_param =
        LFO_UNAPPLIED_PARAMS.include?(param) &&
        solution[:lfo_pitch_int] == 0 &&
        solution[:lfo_cutoff_int] == 0

      skip_delay_param = param == :delay_time && solution[:delay_feedback] == 0

      next if skip_lfo_param || skip_delay_param

      if value.is_a?(Numeric) && param != :voice
        worst_possible_score = value >= 63 ? 0 : 127
        error = (guess[param].to_i - value.to_i).abs
        score = (1.0 - (error.to_f / (worst_possible_score - value).abs)) * 100.0
        scores[param] = [value, guess[param], error, score.round(2)]
      else
        score = guess[param].to_s == value.to_s ? 100.0 : 0.0
        scores[param] = [value, guess[param], score == 100.0 ? 0 : 127, score]
      end
    end
  end
end
