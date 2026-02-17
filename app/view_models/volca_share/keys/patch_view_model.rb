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

      def mystery_patch_params
        # merge some salt values into emulator query string params
        params = emulator_query_string.merge(
          {
            homer: 'stupid',
            marge: 'blue hair',
            bart: 'eat my shorts',
            lisa: 'smart',
            maggie: 'pacifier',
          }
        )

        #shuffle the params to obfuscate them a bit more
        params = params.to_a.shuffle.to_h


        # encodes to base64 to obfuscate the params a bit
        base64_encoded_params = Base64.strict_encode64(params.to_json)

        # add on some more salt
        salt_to_add = Base64.strict_encode64('salt' + Time.now.utc.day.to_s)

        combined_string = base64_encoded_params + salt_to_add

        # rotate the characters by todays day of month (UTC)
        rotation_amount = Time.now.utc.day

        rotated_string = combined_string.chars.map do |char|
          if char.match?(/[A-Za-z0-9\+\=\/]/)
            ((char.ord - 32 + rotation_amount) % 95 + 32).chr
          else
            char
          end
        end.join


        { patch: rotated_string }
      end
    end
  end
end
