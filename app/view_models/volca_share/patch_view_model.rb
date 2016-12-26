module VolcaShare
  class PatchViewModel < ApplicationViewModel
    def vco_group_one
      return true if vco_group == 'one'
      false
    end

    def vco_group_two
      return true if vco_group == 'two'
      false
    end

    def vco_group_three
      return true if vco_group == 'three'
      false
    end

    def checked?(field)
      return { checked: true } if model.send(field)
      {}
    end

    def username
      model.user.try(:username)
    end

    def audio_sample_code
      return unless model.audio_sample.present?
      @audio_sample_code ||=
        if audio_sample.include?('soundcloud')
          ::OEmbed::Providers::SoundCloud.get(audio_sample, maxheight: 81).html
        elsif audio_sample.include?('freesound')
          freesound_id = /\d{6}/.match(audio_sample).to_s
          return unless freesound_id.present?
          "<iframe frameborder='0' scrolling='no' src='https://www.freesound.org/embed/sound/iframe/#{freesound_id}/simple/small/' width='375' height='30'></iframe>"
        end
    end

    def description
      return unless model.notes.present?
      return model.notes.squish if model.notes.squish.length <= 180
      model.notes[0..80].squish + '...'
    end

    def formatted_tags
      tags.map(&:downcase).join(', ')
    end

    def show_midi_only_knobs?
      model.slide_time != 63 ||
        model.expression != 127 ||
        model.gate_time != 127
    end
  end
end
