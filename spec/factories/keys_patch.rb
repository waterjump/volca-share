# frozen_string_literal: true

FactoryBot.define do
  factory :keys_patch, class: Keys::Patch do |_p|
    name { FFaker::Lorem.characters(10) }
    notes { FFaker::Lorem.paragraph }
    voice { [10, 30, 50, 70, 100, 120].sample }
    octave { [10, 30, 50, 70, 100, 120].sample }
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

    slug { name.parameterize }
  end
end
