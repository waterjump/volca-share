# frozen_string_literal: true

module VolcaShare
  class PatchViewModel < ApplicationViewModel
    include AudioRegex
    def vco_group_one
      vco_group == 'one'
    end

    def vco_group_two
      vco_group == 'two'
    end

    def vco_group_three
      vco_group == 'three'
    end

    def checked?(field)
      return { checked: true } if model.send(field)
      {}
    end

    def lit?(field)
      return 'lit' if model.send(field)
      ''
    end

    def index_classes
      classes = []
      classes << 'secret' if secret
      classes << 'has-audio' if audio_sample.present?
    end

    def username
      user.try(:username)
    end

    def audio_sample_code
      return unless audio_sample.present?
      @audio_sample_code ||=
        if audio_sample.include?('soundcloud')
          ::OEmbed::Providers::SoundCloud.get(audio_sample, maxheight: 81).html
        elsif /youtu\.?be/ === audio_sample
          ::OEmbed::Providers::Youtube.get(audio_sample).html
        elsif audio_sample.include?('freesound')
          freesound_id = /\d{2,7}/.match(audio_sample).to_s
          return unless freesound_id.present?
          "<iframe frameborder='0' scrolling='no' src='http://www.freesound."\
          "org/embed/sound/iframe/#{freesound_id}/simple/small/' width='375'"\
          " height='30'></iframe>"
        end
    end

    def description
      return unless notes.present?
      return notes.squish if notes.squish.length <= 100
      "#{notes.squish[0..96].split(' ')[0..-2].join(' ')}..."
    end

    def formatted_tags
      tags.map(&:downcase).join(', ')
    end

    def show_midi_only_knobs?
      slide_time != 63 || expression != 127 || gate_time != 127
    end
  end
end
