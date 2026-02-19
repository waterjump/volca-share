# frozen_string_literal: true

class UpdatePatchAudioSampleAvailableJob
  BATCH_SIZE = 200

  def perform
    update_scope(Patch)
    update_scope(Keys::Patch)

    nil
  end

  private

  def update_scope(klass)
    scope =
      klass.where(:audio_sample.exists => true)
           .only(:_id, :name, :audio_sample, :audio_sample_available)
           .batch_size(BATCH_SIZE)

    scope.each do |patch|
      current = patch.audio_sample_available?
      desired = patch.send(:set_audio_sample_available)

      next if current == desired

      log_fix(patch, current, desired)
      patch.set(audio_sample_available: desired)
    end
  end

  def log_fix(patch, current, desired)
    return if Rails.env.test?

    puts "Correcting audio sample availability for '#{patch.name}': " \
         "#{current.inspect} -> #{desired.inspect}"
  end
end

