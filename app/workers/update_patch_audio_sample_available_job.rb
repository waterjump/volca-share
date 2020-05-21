# frozen_string_literal: true

class UpdatePatchAudioSampleAvailableJob
  def perform
    all_patches = Patch.all + Keys::Patch.all

    all_patches.each do |patch|
      next unless patch.audio_sample.present?

      original_availability = patch.audio_sample_available?

      next if original_availability == patch.send(:set_audio_sample_available)

      puts "Correcting audio sample availibility for '#{patch.name}'"
      patch.set(audio_sample_available: patch.send(:set_audio_sample_available))
    end

    nil
  end
end

