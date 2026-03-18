# frozen_string_literal: true

class MysteryPatchHintFinder
  def initialize(mystery_patch:, guess:)
    @mystery_patch = mystery_patch
    @guess = guess
  end

  def hint_params
    scorer
      .score[:parameter_scores]
      .sort_by { |param_name, (_actual, _guess, error, _accuracy)| [-error, param_name.to_s] }
      .first(2)
      .map(&:first)
  end

  private

  attr_reader :mystery_patch, :guess

  def scorer
    @scorer ||= MysteryPatchScorer.new(
      VolcaShare::Keys::PatchViewModel.wrap(mystery_patch).emulator_query_string,
      guess
    )
  end
end
