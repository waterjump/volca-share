# frozen_string_literal: true

class AudioSampleValidator < ActiveModel::EachValidator
  include AudioRegex
  def self.kind
    :custom
  end

  def validate_each(record, _attribute, _value)
    return unless record.audio_sample.present?
    unless compare(record.audio_sample)
      record.errors[:audio_sample] <<
        'needs to be direct SoundCloud, Freesound or YouTube link.'
    end
  end

  def compare(audio_sample)
    regexes.any? do |regex|
      !!(audio_sample =~ Regexp.new("#{prefix}#{regex}#{suffix}"))
    end
  end
end
