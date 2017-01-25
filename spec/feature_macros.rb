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
  find("#{bottom_row_form} > label:nth-child(4)").click  # vco_group_two
  find("#{bottom_row_form} > label:nth-child(9)").click  # lfo_target_amp
  find("#{bottom_row_form} > label:nth-child(12)").click # lfo_target_pitch
  find("#{bottom_row_form} > label:nth-child(15)").click # lfo_target_cutoff
  find("#{bottom_row_form} > label:nth-child(18)").click # lfo_wave
  find("#{bottom_row_form} > label:nth-child(21)").click # vco1_wave
  find("#{bottom_row_form} > label:nth-child(24)").click # vco2_wave
  find("#{bottom_row_form} > label:nth-child(27)").click # vco3_wave
  find("#{bottom_row_form} > label:nth-child(30)").click # sustain_on
  find("#{bottom_row_form} > label:nth-child(33)").click # amp_eg_on
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

def bottom_row
  '#interface > div.stretchy > div > div.bottom-row'
end

def bottom_row_form
  '#patch_form > div#interface.col-lg-9 > div.stretchy > div > div.bottom-row'
end
