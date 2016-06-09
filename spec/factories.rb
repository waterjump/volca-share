FactoryGirl.define do
  factory :patch do
    name { Ffaker::Lorem.word }
    attack (0..127).to_a.sample
    decay_release (0..127).to_a.sample
    cutoff_eg_int (0..127).to_a.sample
    peak (0..127).to_a.sample
    cutoff (0..127).to_a.sample
    lfo_rate (0..127).to_a.sample
    lfo_int (0..127).to_a.sample
    vco1_pitch (0..127).to_a.sample
    vco1_active { Ffaker::Boolean.maybe }
    vco2_pitch (0..127).to_a.sample
    vco2_active { Ffaker::Boolean.maybe }
    vco3_pitch (0..127).to_a.sample
    vco3_active { Ffaker::Boolean.maybe }
    vco_group %w(one two three).sample
    lfo_target_amp { Ffaker::Boolean.maybe }
    lfo_target_pitch { Ffaker::Boolean.maybe }
    lfo_target_cutoff { Ffaker::Boolean.maybe }
    lfo_wave %w(triangle square).sample
    vco1_wave %w(saw square).sample
    vco2_wave %w(saw square).sample
    vco3_wave %w(saw square).sample
    sustain_on { Ffaker::Boolean.maybe }
    amp_eg_on { Ffaker::Boolean.maybe }
    tags { Ffaker::Lorem.words(3) }
    privacy { Ffaker::Boolean.maybe }
    audio_link { Ffaker::Internet.uri('http') }
    additional_notes { Ffaker::Lorem.paragraph }
  end

  factory :user do
    email { FFaker::Internet.email }
    password { Devise.friendly_token.first(8) }
  end
end
