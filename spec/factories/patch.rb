# frozen_string_literal: true

def midi_range
  0..127
end

FactoryBot.define do
  factory :patch do |_p|
    name { FFaker::Lorem.characters(10) }
    attack midi_range.to_a.sample
    decay_release midi_range.to_a.sample
    cutoff_eg_int midi_range.to_a.sample
    octave midi_range.to_a.sample
    peak midi_range.to_a.sample
    cutoff midi_range.to_a.sample
    lfo_rate midi_range.to_a.sample
    lfo_int midi_range.to_a.sample
    vco1_pitch midi_range.to_a.sample
    vco1_active { FFaker::Boolean.maybe }
    vco2_pitch midi_range.to_a.sample
    vco2_active { FFaker::Boolean.maybe }
    vco3_pitch midi_range.to_a.sample
    vco3_active { FFaker::Boolean.maybe }
    vco_group %w[one two three].sample
    lfo_target_amp { FFaker::Boolean.maybe }
    lfo_target_pitch { FFaker::Boolean.maybe }
    lfo_target_cutoff { FFaker::Boolean.maybe }
    lfo_wave { FFaker::Boolean.maybe }
    vco1_wave { FFaker::Boolean.maybe }
    vco2_wave { FFaker::Boolean.maybe }
    vco3_wave { FFaker::Boolean.maybe }
    sustain_on { FFaker::Boolean.maybe }
    amp_eg_on { FFaker::Boolean.maybe }
    secret false
    notes { FFaker::Lorem.paragraph }
    tags { FFaker::Lorem.words(3) }
    slide_time midi_range.to_a.sample
    expression midi_range.to_a.sample
    gate_time midi_range.to_a.sample
    audio_sample 'https://soundcloud.com/69bot/shallow'
    slug { name.parameterize }

    factory :patch_with_sequences do
      transient do
        sequence_count 3
      end
      after(:build) do |patch, evaluator|
        build_list(:sequence, evaluator.sequence_count, patch: patch)
      end
    end
  end
end
