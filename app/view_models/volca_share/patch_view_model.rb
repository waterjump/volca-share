# frozen_string_literal: true

module VolcaShare
  class PatchViewModel < ApplicationViewModel
    include AudioRegex
    include Shared

    def vco_group_one
      vco_group == 'one'
    end

    def vco_group_two
      vco_group == 'two'
    end

    def vco_group_three
      vco_group == 'three'
    end

    def index_classes
      classes = []
      classes << 'secret' if secret
      classes << 'has-audio' if audio_sample.present?
    end

    def username
      user.try(:username)
    end

    def show_midi_only_knobs?
      slide_time != 63 || expression != 127 || gate_time != 127
    end
  end
end
