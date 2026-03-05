# frozen_string_literal: true

class CreateRandomMysteryPatchJob
  def perform
    MysteryPatch.generate_random.save
  end
end
