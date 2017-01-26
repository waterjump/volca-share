def login(usr = user)
  click_link 'Log in'
  within '#login' do
    fill_in 'user[email]', with: usr.email
    fill_in 'user[password]', with: usr.password
    click_button 'Log in'
  end
end

def fill_out_patch_form(dummy_patch, anon = false)
  range_select 'patch[attack]', dummy_patch.attack
  range_select 'patch[decay_release]', dummy_patch.decay_release
  range_select 'patch[cutoff_eg_int]', dummy_patch.cutoff_eg_int
  range_select 'patch[octave]', dummy_patch.octave
  range_select 'patch[peak]', dummy_patch.peak
  range_select 'patch[cutoff]', dummy_patch.cutoff
  range_select 'patch[lfo_rate]', dummy_patch.lfo_rate
  range_select 'patch[lfo_int]', dummy_patch.lfo_int
  range_select 'patch[vco1_pitch]', dummy_patch.vco1_pitch
  range_select 'patch[slide_time]', dummy_patch.slide_time
  range_select 'patch[expression]', dummy_patch.expression
  range_select 'patch[gate_time]', dummy_patch.gate_time
  find('#vco1_active_button').click
  range_select 'patch[vco2_pitch]', dummy_patch.vco2_pitch
  find('#vco2_active_button').click
  range_select 'patch[vco3_pitch]', dummy_patch.vco3_pitch
  find('#vco3_active_button').click
  find('#vco_group_two_light').click
  find('#lfo_target_amp_light').click
  find('#lfo_target_pitch_light').click
  find('#lfo_target_cutoff_light').click
  find('#lfo_wave_light').click
  find('#vco1_wave_light').click
  find('#vco2_wave_light').click
  find('#vco3_wave_light').click
  find('#sustain_on_light').click
  find('#amp_eg_on_light').click
  fill_in 'patch[name]', with: dummy_patch.name
  fill_in 'patch[notes]', with: dummy_patch.notes
  unless anon
    check 'patch[secret]'
    fill_in 'patch[audio_sample]', with: dummy_patch.audio_sample
  end
end

def range_select(name, value)
  selector = %(input[type=range][name=\\"#{name}\\"])
  script = %-$("#{selector}").val(#{value})-
  page.execute_script(script)
end

def seq_form_light(seq, step, param)
  page.find(
    "label[for=patch_sequences_attributes_#{seq}_step_#{step}_#{param}]"
  )
end
