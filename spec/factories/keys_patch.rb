# frozen_string_literal: true

FactoryBot.define do
  factory :keys_patch, class: Keys::Patch do |_p|
    name { FFaker::Lorem.characters(10) }
    voice { midi_range.to_a.sample }
    octave { midi_range.to_a.sample }
    detune { midi_range.to_a.sample }
    portamento { midi_range.to_a.sample }
    vco_eg_int { midi_range.to_a.sample }
    cutoff { midi_range.to_a.sample }
    peak { midi_range.to_a.sample }
    vcf_eg_int { midi_range.to_a.sample }
    lfo_rate { midi_range.to_a.sample }
    lfo_pitch_int { midi_range.to_a.sample }
    lfo_cutoff_int { midi_range.to_a.sample }
    attack { midi_range.to_a.sample }
    decay_release { midi_range.to_a.sample }
    sustain { midi_range.to_a.sample }
    delay_time { midi_range.to_a.sample }
    delay_feedback { midi_range.to_a.sample }
    lfo_shape { %w(saw triangle square).sample }
    lfo_trigger_sync { FFaker::Boolean.maybe }
    step_trigger { FFaker::Boolean.maybe }
    tempo_delay { FFaker::Boolean.maybe }
  end
end
