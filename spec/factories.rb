FactoryGirl.define do
  factory :patch do
    name { FFaker::Lorem.word }
    attack (0..100).to_a.sample
    decay_release (0..100).to_a.sample
    cutoff_eg_int (0..100).to_a.sample
    peak (0..100).to_a.sample
    cutoff (0..100).to_a.sample
    lfo_rate (0..100).to_a.sample
    lfo_int (0..100).to_a.sample
    vco1_pitch (0..100).to_a.sample
    vco1_active { FFaker::Boolean.maybe }
    vco2_pitch (0..100).to_a.sample
    vco2_active { FFaker::Boolean.maybe }
    vco3_pitch (0..100).to_a.sample
    vco3_active { FFaker::Boolean.maybe }
    vco_group %w(one two three).sample
    lfo_target_amp { FFaker::Boolean.maybe }
    lfo_target_pitch { FFaker::Boolean.maybe }
    lfo_target_cutoff { FFaker::Boolean.maybe }
    lfo_wave %w(triangle square).sample
    vco1_wave %w(saw square).sample
    vco2_wave %w(saw square).sample
    vco3_wave %w(saw square).sample
    sustain_on { FFaker::Boolean.maybe }
    amp_eg_on { FFaker::Boolean.maybe }
    private? { FFaker::Boolean.maybe }
    notes { FFaker::Lorem.paragraph }
  end

  factory :user do
    email { FFaker::Internet.email }
    password { Devise.friendly_token.first(8) }
  end
end
