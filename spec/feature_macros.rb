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
  find('#vco1_active_button').click unless dummy_patch.vco1_active
  range_select 'patch[vco2_pitch]', dummy_patch.vco2_pitch
  find('#vco2_active_button').click unless dummy_patch.vco2_active
  range_select 'patch[vco3_pitch]', dummy_patch.vco3_pitch
  find('#vco3_active_button').click unless dummy_patch.vco3_active
  find('#vco_group_one_light').click if dummy_patch.vco_group == 'one'
  find('#vco_group_two_light').click if dummy_patch.vco_group == 'two'
  find('#vco_group_three_light').click if dummy_patch.vco_group == 'three'
  find('#lfo_target_amp_light').click if dummy_patch.lfo_target_amp
  find('#lfo_target_pitch_light').click if dummy_patch.lfo_target_pitch
  find('#lfo_target_cutoff_light').click unless dummy_patch.lfo_target_cutoff
  find('#lfo_wave_light').click if dummy_patch.lfo_wave
  find('#vco1_wave_light').click if dummy_patch.vco1_wave
  find('#vco2_wave_light').click if dummy_patch.vco2_wave
  find('#vco3_wave_light').click unless dummy_patch.vco3_wave
  find('#sustain_on_light').click if dummy_patch.sustain_on
  find('#amp_eg_on_light').click if dummy_patch.amp_eg_on
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

def reflects_patch(dummy_patch)
  expect(page.find('#attack')['data-midi']).to eq(dummy_patch.attack.to_s)
  expect(page.find('#decay_release')['data-midi']).to eq(dummy_patch.decay_release.to_s)
  expect(page.find('#cutoff_eg_int')['data-midi']).to eq(dummy_patch.cutoff_eg_int.to_s)
  expect(page.find('#octave')['data-midi']).to eq(dummy_patch.octave.to_s)
  expect(page.find('#peak')['data-midi']).to eq(dummy_patch.peak.to_s)
  expect(page.find('#cutoff')['data-midi']).to eq(dummy_patch.cutoff.to_s)
  expect(page.find('#lfo_rate')['data-midi']).to eq(dummy_patch.lfo_rate.to_s)
  expect(page.find('#lfo_int')['data-midi']).to eq(dummy_patch.lfo_int.to_s)
  expect(page.find('#vco1_pitch')['data-midi']).to eq(dummy_patch.vco1_pitch.to_s)
  expect(page.find('#vco2_pitch')['data-midi']).to eq(dummy_patch.vco2_pitch.to_s)
  expect(page.find('#vco3_pitch')['data-midi']).to eq(dummy_patch.vco3_pitch.to_s)
  expect(page.find('#slide_time', visible: false)['data-midi']).to eq(dummy_patch.slide_time.to_s)
  expect(page.find('#expression', visible: false)['data-midi']).to eq(dummy_patch.expression.to_s)
  expect(page.find('#gate_time', visible: false)['data-midi']).to eq(dummy_patch.gate_time.to_s)
  expect(page.find('#vco1_active_button')['data-active']).to eq(dummy_patch.vco1_active.to_s)
  expect(page.find('#vco2_active_button')['data-active']).to eq(dummy_patch.vco2_active.to_s)
  expect(page.find('#vco3_active_button')['data-active']).to eq(dummy_patch.vco3_active.to_s)
  expect(page.find('#vco_group_one_light')['data-active']).to eq((dummy_patch.vco_group == 'one').to_s)
  expect(page.find('#vco_group_two_light')['data-active']).to eq((dummy_patch.vco_group == 'two').to_s)
  expect(page.find('#vco_group_three_light')['data-active']).to eq((dummy_patch.vco_group == 'three').to_s)
  expect(page.find('#lfo_target_amp_light')['data-active']).to eq(dummy_patch.lfo_target_amp.to_s)
  expect(page.find('#lfo_target_pitch_light')['data-active']).to eq(dummy_patch.lfo_target_pitch.to_s)
  expect(page.find('#lfo_target_cutoff_light')['data-active']).to eq(dummy_patch.lfo_target_cutoff.to_s)
  expect(page.find('#lfo_wave_light')['data-active']).to eq(dummy_patch.lfo_wave.to_s)
  expect(page.find('#vco1_wave_light')['data-active']).to eq(dummy_patch.vco1_wave.to_s)
  expect(page.find('#vco2_wave_light')['data-active']).to eq(dummy_patch.vco2_wave.to_s)
  expect(page.find('#vco3_wave_light')['data-active']).to eq(dummy_patch.vco3_wave.to_s)
  expect(page.find('#sustain_on_light')['data-active']).to eq(dummy_patch.sustain_on.to_s)
  expect(page.find('#amp_eg_on_light')['data-active']).to eq(dummy_patch.amp_eg_on.to_s)
  expect(page).to have_content(dummy_patch.name)
  expect(page).to have_content(dummy_patch.notes)
end
