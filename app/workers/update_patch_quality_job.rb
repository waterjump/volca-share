# frozen_string_literal: true

class UpdatePatchQualityJob
  include Sidekiq::Worker

  def perform
    Patch.all.each(&:persist_quality)
  end
end

