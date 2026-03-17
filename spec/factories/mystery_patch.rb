# frozen_string_literal: true

FactoryBot.define do
  factory :mystery_patch, class: MysteryPatch do |_p|
    voice { MysteryPatch::VOICE_MIDI_VALUES.sample }
    detune { rand(128) }
    portamento { rand(128) }
    vco_eg_int { rand(128) }
    cutoff { rand(128) }
    peak { rand(128) }
    vcf_eg_int { rand(128) }
    lfo_rate { rand(128) }
    lfo_pitch_int { rand(128) }
    lfo_cutoff_int { rand(128) }
    attack { rand(128) }
    decay_release { rand(128) }
    sustain { rand(128) }
    delay_time { rand(128) }
    delay_feedback { rand(128) }
    lfo_shape { %w(saw triangle square).sample }
    lfo_trigger_sync { FFaker::Boolean.maybe }
    step_trigger { FFaker::Boolean.maybe }
    tempo_delay { FFaker::Boolean.maybe }
  end
end
