json.array!(@patches) do |patch|
  json.extract! patch, :id, :name, :tempo, :attack, :decay_release, :cutoff_eg_int, :peak, :cutoff, :lfo_rate, :lfo_int, :vco1_pitch, :vco1_active, :vco2_pitch, :vco2_active, :vco3_pitch, :vco3_active, :vco_group, :lfo_target_amp, :lfo_target_pitch, :lfo_target_cutoff, :lfo_wave, :vco1_wave, :vco2_wave, :vco3_wave, :sustain_on, :amp_eg_on, :tags, :type
  json.url patch_url(patch, format: :json)
end
