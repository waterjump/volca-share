# frozen_string_literal: true

class UpdatePatchQualityJob
  def perform
    Patch.all.each(&:persist_quality)
  end
end

