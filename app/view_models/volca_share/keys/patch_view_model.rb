# frozen_string_literal: true

module VolcaShare
  module Keys
    class PatchViewModel < ApplicationViewModel
      include AudioRegex
      include Shared

      def lfo_shape_saw
        model.lfo_shape == 'saw'
      end

      def lfo_shape_triangle
        model.lfo_shape == 'triangle'
      end

      def lfo_shape_square
        model.lfo_shape == 'square'
      end

      def emulator_query_string
        {
          voice: voice,
          octave: octave,
          detune: detune,
          portamento: portamento,
          vco_eg_int: vco_eg_int,
          cutoff: cutoff,
          peak: peak,
          vcf_eg_int: vcf_eg_int,
          lfo_rate: lfo_rate,
          lfo_pitch_int: lfo_pitch_int,
          lfo_cutoff_int: lfo_cutoff_int,
          attack: attack,
          decay_release: decay_release,
          sustain: sustain,
          delay_time: delay_time,
          delay_feedback: delay_feedback,
          lfo_shape: lfo_shape,
          lfo_trigger_sync: lfo_trigger_sync
        }
      end
    end
  end
end
