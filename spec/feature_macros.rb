def login(usr = user)
  click_link 'Log in'
  within '#login' do
    fill_in 'user[email]', with: usr.email
    fill_in 'user[password]', with: usr.password
    click_button 'Log in'
  end
end

def fill_out_patch_form(patch, anon = false)
  range_select 'patch[attack]', patch.attack
  range_select 'patch[decay_release]', patch.decay_release
  range_select 'patch[cutoff_eg_int]', patch.cutoff_eg_int
  range_select 'patch[octave]', patch.octave
  range_select 'patch[peak]', patch.peak
  range_select 'patch[cutoff]', patch.cutoff
  range_select 'patch[lfo_rate]', patch.lfo_rate
  range_select 'patch[lfo_int]', patch.lfo_int
  range_select 'patch[vco1_pitch]', patch.vco1_pitch
  range_select 'patch[slide_time]', patch.slide_time
  range_select 'patch[expression]', patch.expression
  range_select 'patch[gate_time]', patch.gate_time
  find('#vco1_active_button').click unless patch.vco1_active
  range_select 'patch[vco2_pitch]', patch.vco2_pitch
  find('#vco2_active_button').click unless patch.vco2_active
  range_select 'patch[vco3_pitch]', patch.vco3_pitch
  find('#vco3_active_button').click unless patch.vco3_active
  find('#vco_group_one_light').click if patch.vco_group == 'one'
  find('#vco_group_two_light').click if patch.vco_group == 'two'
  find('#vco_group_three_light').click if patch.vco_group == 'three'
  find('#lfo_target_amp_light').click if patch.lfo_target_amp
  find('#lfo_target_pitch_light').click if patch.lfo_target_pitch
  find('#lfo_target_cutoff_light').click unless patch.lfo_target_cutoff
  find('#lfo_wave_light').click if patch.lfo_wave
  find('#vco1_wave_light').click if patch.vco1_wave
  find('#vco2_wave_light').click if patch.vco2_wave
  find('#vco3_wave_light').click unless patch.vco3_wave
  find('#sustain_on_light').click if patch.sustain_on
  find('#amp_eg_on_light').click if patch.amp_eg_on
  fill_in 'patch[name]', with: patch.name
  fill_in 'patch[notes]', with: patch.notes
  unless anon
    check 'patch[secret]'
    fill_in 'patch[audio_sample]', with: patch.audio_sample
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

def reflects_patch(patch)
  # Knobs
  expect(page.find('#attack')['data-midi']).to eq(patch.attack.to_s)
  expect(page.find('#decay_release')['data-midi']).to eq(patch.decay_release.to_s)
  expect(page.find('#cutoff_eg_int')['data-midi']).to eq(patch.cutoff_eg_int.to_s)
  expect(page.find('#octave')['data-midi']).to eq(patch.octave.to_s)
  expect(page.find('#peak')['data-midi']).to eq(patch.peak.to_s)
  expect(page.find('#cutoff')['data-midi']).to eq(patch.cutoff.to_s)
  expect(page.find('#lfo_rate')['data-midi']).to eq(patch.lfo_rate.to_s)
  expect(page.find('#lfo_int')['data-midi']).to eq(patch.lfo_int.to_s)
  expect(page.find('#vco1_pitch')['data-midi']).to eq(patch.vco1_pitch.to_s)
  expect(page.find('#vco2_pitch')['data-midi']).to eq(patch.vco2_pitch.to_s)
  expect(page.find('#vco3_pitch')['data-midi']).to eq(patch.vco3_pitch.to_s)
  expect(page).to have_css('#vco1_pitch.lit') if patch.vco1_active
  expect(page).to have_css('#vco2_pitch.lit') if patch.vco2_active
  expect(page).to have_css('#vco3_pitch.lit') if patch.vco3_active
  expect(page).not_to have_css('#vco1_pitch.lit') unless patch.vco1_active
  expect(page).not_to have_css('#vco2_pitch.lit') unless patch.vco2_active
  expect(page).not_to have_css('#vco3_pitch.lit') unless patch.vco3_active
  expect(page.find('#slide_time', visible: false)['data-midi']).to eq(patch.slide_time.to_s)
  expect(page.find('#expression', visible: false)['data-midi']).to eq(patch.expression.to_s)
  expect(page.find('#gate_time', visible: false)['data-midi']).to eq(patch.gate_time.to_s)

  # Buttons
  expect(page.find('#vco1_active_button')['data-active']).to eq(patch.vco1_active.to_s)
  expect(page.find('#vco2_active_button')['data-active']).to eq(patch.vco2_active.to_s)
  expect(page.find('#vco3_active_button')['data-active']).to eq(patch.vco3_active.to_s)
  expect(page).to have_css('#vco1_active_button.lit') if patch.vco1_active
  expect(page).to have_css('#vco2_active_button.lit') if patch.vco2_active
  expect(page).to have_css('#vco3_active_button.lit') if patch.vco3_active
  expect(page).not_to have_css('#vco1_active_button.lit') unless patch.vco1_active
  expect(page).not_to have_css('#vco2_active_button.lit') unless patch.vco2_active
  expect(page).not_to have_css('#vco3_active_button.lit') unless patch.vco3_active

  # Lights
  expect(page.find('#vco_group_one_light')['data-active']).to eq((patch.vco_group == 'one').to_s)
  expect(page.find('#vco_group_two_light')['data-active']).to eq((patch.vco_group == 'two').to_s)
  expect(page.find('#vco_group_three_light')['data-active']).to eq((patch.vco_group == 'three').to_s)
  expect(page).to have_css('#vco_group_one_light.lit') if patch.vco_group == 'one'
  expect(page).to have_css('#vco_group_two_light.lit') if patch.vco_group == 'two'
  expect(page).to have_css('#vco_group_three_light.lit') if patch.vco_group == 'three'
  expect(page).not_to have_css('#vco_group_one_light.lit') unless patch.vco_group == 'one'
  expect(page).not_to have_css('#vco_group_two_light.lit') unless patch.vco_group == 'two'
  expect(page).not_to have_css('#vco_group_three_light.lit') unless patch.vco_group == 'three'
  expect(page.find('#lfo_target_amp_light')['data-active']).to eq(patch.lfo_target_amp.to_s)
  expect(page).to have_css('#lfo_target_amp_light.lit') if patch.lfo_target_amp
  expect(page).not_to have_css('#lfo_target_amp_light.lit') unless patch.lfo_target_amp
  expect(page.find('#lfo_target_pitch_light')['data-active']).to eq(patch.lfo_target_pitch.to_s)
  expect(page).to have_css('#lfo_target_pitch_light.lit') if patch.lfo_target_pitch
  expect(page).not_to have_css('#lfo_target_pitch_light.lit') unless patch.lfo_target_pitch
  expect(page.find('#lfo_target_cutoff_light')['data-active']).to eq(patch.lfo_target_cutoff.to_s)
  expect(page).to have_css('#lfo_target_cutoff_light.lit') if patch.lfo_target_cutoff
  expect(page).not_to have_css('#lfo_target_cutoff_light.lit') unless patch.lfo_target_cutoff
  expect(page.find('#lfo_wave_light')['data-active']).to eq(patch.lfo_wave.to_s)
  expect(page).to have_css('#lfo_wave_light.lit') if patch.lfo_wave
  expect(page).not_to have_css('#lfo_wave_light.lit') unless patch.lfo_wave
  expect(page.find('#vco1_wave_light')['data-active']).to eq(patch.vco1_wave.to_s)
  expect(page).to have_css('#vco1_wave_light.lit') if patch.vco1_wave
  expect(page).not_to have_css('#vco1_wave_light.lit') unless patch.vco1_wave
  expect(page.find('#vco2_wave_light')['data-active']).to eq(patch.vco2_wave.to_s)
  expect(page).to have_css('#vco2_wave_light.lit') if patch.vco2_wave
  expect(page).not_to have_css('#vco2_wave_light.lit') unless patch.vco2_wave
  expect(page.find('#vco3_wave_light')['data-active']).to eq(patch.vco3_wave.to_s)
  expect(page).to have_css('#vco3_wave_light.lit') if patch.vco3_wave
  expect(page).not_to have_css('#vco3_wave_light.lit') unless patch.vco3_wave
  expect(page.find('#sustain_on_light')['data-active']).to eq(patch.sustain_on.to_s)
  expect(page).to have_css('#sustain_on_light.lit') if patch.sustain_on
  expect(page).not_to have_css('#sustain_on_light.lit') unless patch.sustain_on
  expect(page.find('#amp_eg_on_light')['data-active']).to eq(patch.amp_eg_on.to_s)
  expect(page).to have_css('#amp_eg_on_light.lit') if patch.amp_eg_on
  expect(page).not_to have_css('#amp_eg_on_light.lit') unless patch.amp_eg_on
  expect(page).to have_content(patch.name)
  expect(page).to have_content(patch.notes)
end
