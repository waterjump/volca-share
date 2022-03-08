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

    def username
      user.try(:username)
    end

    def show_midi_only_knobs?
      slide_time != 63 || expression != 127 || gate_time != 127
    end

    def emulator_query_string
      {
        attack: attack,
        decay_release: decay_release,
        cutoff_eg_int: cutoff_eg_int,
        octave: octave,
        peak: peak,
        cutoff: cutoff,
        lfo_rate: lfo_rate,
        lfo_int: lfo_int,
        vco1_pitch: vco1_pitch,
        vco2_pitch: vco2_pitch,
        vco3_pitch: vco3_pitch,
        vco1_active: vco1_active,
        vco2_active: vco2_active,
        vco3_active: vco3_active,
        vco_group: vco_group,
        lfo_target_amp: lfo_target_amp,
        lfo_target_pitch: lfo_target_pitch,
        lfo_target_cutoff: lfo_target_cutoff,
        lfo_wave: lfo_wave ? 'square' : 'triangle',
        vco1_wave: vco1_wave ? 'square' : 'sawtooth',
        vco2_wave: vco2_wave ? 'square' : 'sawtooth',
        vco3_wave: vco3_wave ? 'square' : 'sawtooth',
        sustain_on: sustain_on,
        amp_eg_on: amp_eg_on
      }
    end
  end
end
