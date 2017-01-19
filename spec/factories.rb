FactoryGirl.define do
  factory :patch do |_p|
    name { FFaker::Lorem.characters(10) }
    attack (0..127).to_a.sample
    decay_release (0..127).to_a.sample
    cutoff_eg_int (0..127).to_a.sample
    octave (0..127).to_a.sample
    peak (0..127).to_a.sample
    cutoff (0..127).to_a.sample
    lfo_rate (0..127).to_a.sample
    lfo_int (0..127).to_a.sample
    vco1_pitch (0..127).to_a.sample
    vco1_active { FFaker::Boolean.maybe }
    vco2_pitch (0..127).to_a.sample
    vco2_active { FFaker::Boolean.maybe }
    vco3_pitch (0..127).to_a.sample
    vco3_active { FFaker::Boolean.maybe }
    vco_group %w(one two three).sample
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
    slide_time (0..127).to_a.sample
    expression (0..127).to_a.sample
    gate_time (0..127).to_a.sample
    audio_sample 'https://soundcloud.com/69bot/shallow'
    slug { name.parameterize }
  end

  factory :sequence do |_s|
    association :patch
  end

  factory :step do
    association :sequence
    index (1..16).to_a.sample
    note (0..127).to_a.sample
    step_mode { FFaker::Boolean.maybe }
    slide { FFaker::Boolean.maybe }
    active_step { FFaker::Boolean.maybe }
  end

  factory :user do
    username { FFaker::Internet.user_name[0..19] }
    email { FFaker::Internet.email }
    password { Devise.friendly_token.first(8) }
    slug { username.parameterize }
  end
end
