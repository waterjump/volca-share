# frozen_string_literal: true

module VolcaShare
  module Shared
    def checked?(field)
      return { checked: true } if model.send(field)
      {}
    end

    def description
      return unless notes.present?
      return notes.squish if notes.squish.length <= 100
      "#{notes.squish[0..96].split(' ')[0..-2].join(' ')}..."
    end

    def lit?(field)
      return 'lit' if model.send(field)
      'unlit'
    end

    def formatted_tags
      tags.map(&:downcase).join(', ')
    end

    def index_classes
      return [] unless model.audio_sample_available?
      %w(has-audio)
    end
  end
end
