# frozen_string_literal: true

def login(usr = user)
  visit new_user_session_path
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
  fill_in 'patch[tags]', with: patch.tags.join(', '), visible: false
  return if anon
  check 'patch[secret]' if patch.secret?
  fill_in 'patch[audio_sample]', with: patch.audio_sample
end

def fill_out_keys_patch_form(patch, anon = false)
  fill_in 'patch[name]', with: patch.name
  fill_in 'patch[notes]', with: patch.notes
  range_select 'patch[voice]', patch.voice
  range_select 'patch[octave]', patch.octave
  range_select 'patch[detune]', patch.detune
  range_select 'patch[portamento]', patch.portamento
  range_select 'patch[vco_eg_int]', patch.vco_eg_int
  range_select 'patch[cutoff]', patch.cutoff
  range_select 'patch[peak]', patch.peak
  range_select 'patch[vcf_eg_int]', patch.vcf_eg_int
  range_select 'patch[lfo_rate]', patch.lfo_rate
  range_select 'patch[lfo_pitch_int]', patch.lfo_pitch_int
  range_select 'patch[lfo_cutoff_int]', patch.lfo_cutoff_int
  range_select 'patch[attack]', patch.attack
  range_select 'patch[decay_release]', patch.decay_release
  range_select 'patch[sustain]', patch.sustain
  range_select 'patch[delay_time]', patch.delay_time
  range_select 'patch[delay_feedback]', patch.delay_feedback
  find('#lfo_shape_saw_light').click if patch.lfo_shape == 'saw'
  find('#lfo_shape_triangle_light').click if patch.lfo_shape == 'triangle'
  find('#lfo_shape_square_light').click if patch.lfo_shape == 'square'
  find('#lfo_trigger_sync_light').click if patch.lfo_trigger_sync
  find('#step_trigger_light').click if patch.step_trigger
  find('#tempo_delay_light').click unless patch.tempo_delay
  return if anon
  check 'patch[secret]' if patch.secret?
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

def rotation_from_midi(midi)
  ((midi - 63.5) / (63.5 / 140)).round.to_s
end

def js_knobs_rotated(patch, interface = page)
  expect(interface.find('span.attack', visible: false).text).to(
    eq(rotation_from_midi(patch.attack).to_s)
  )
  expect(interface.find('span.decay_release', visible: false).text).to(
    eq(rotation_from_midi(patch.decay_release).to_s)
  )
  expect(interface.find('span.cutoff_eg_int', visible: false).text).to(
    eq(rotation_from_midi(patch.cutoff_eg_int).to_s)
  )
  expect(interface.find('span.octave', visible: false).text).to(
    eq(rotation_from_midi(patch.octave).to_s)
  )
  expect(interface.find('span.peak', visible: false).text).to(
    eq(rotation_from_midi(patch.peak).to_s)
  )
  expect(interface.find('span.cutoff', visible: false).text).to(
    eq(rotation_from_midi(patch.cutoff).to_s)
  )
  expect(interface.find('span.lfo_rate', visible: false).text).to(
    eq(rotation_from_midi(patch.lfo_rate).to_s)
  )
  expect(interface.find('span.lfo_int', visible: false).text).to(
    eq(rotation_from_midi(patch.lfo_int).to_s)
  )
  expect(interface.find('span.vco1_pitch', visible: false).text).to(
    eq(rotation_from_midi(patch.vco1_pitch).to_s)
  )
  expect(interface.find('span.vco2_pitch', visible: false).text).to(
    eq(rotation_from_midi(patch.vco2_pitch).to_s)
  )
  expect(interface.find('span.vco3_pitch', visible: false).text).to(
    eq(rotation_from_midi(patch.vco3_pitch).to_s)
  )
end

def reflects_patch(patch, options = {})
  interface = options[:interface] || page
  form = options[:form] || false
  # Knobs
  expect(interface).to have_css("#attack[data-midi='#{patch.attack}']")
  expect(interface).to(
    have_css("#decay_release[data-midi='#{patch.decay_release}']")
  )
  expect(interface).to(
    have_css("#cutoff_eg_int[data-midi='#{patch.cutoff_eg_int}']")
  )
  expect(interface).to have_css("#octave[data-midi='#{patch.octave}']")
  expect(interface).to have_css("#peak[data-midi='#{patch.peak}']")
  expect(interface).to have_css("#cutoff[data-midi='#{patch.cutoff}']")
  expect(interface).to have_css("#lfo_rate[data-midi='#{patch.lfo_rate}']")
  expect(interface).to have_css("#lfo_int[data-midi='#{patch.lfo_int}']")
  expect(interface).to have_css("#vco1_pitch[data-midi='#{patch.vco1_pitch}']")
  expect(interface).to have_css("#vco2_pitch[data-midi='#{patch.vco2_pitch}']")
  expect(interface).to have_css("#vco3_pitch[data-midi='#{patch.vco3_pitch}']")

  js_knobs_rotated(patch, page) unless options[:interface].present?

  expect(interface).to have_css('#vco1_pitch.lit') if patch.vco1_active
  expect(interface).to have_css('#vco2_pitch.lit') if patch.vco2_active
  expect(interface).to have_css('#vco3_pitch.lit') if patch.vco3_active
  expect(interface).not_to have_css('#vco1_pitch.lit') unless patch.vco1_active
  expect(interface).not_to have_css('#vco2_pitch.lit') unless patch.vco2_active
  expect(interface).not_to have_css('#vco3_pitch.lit') unless patch.vco3_active

  # Buttons
  if patch.vco1_active
    expect(interface).to have_css('#vco1_active_button.lit')
  else
    expect(interface).not_to have_css('#vco1_active_button.lit')
  end

  if patch.vco2_active
    expect(interface).to have_css('#vco2_active_button.lit')
  else
    expect(interface).not_to have_css('#vco2_active_button.lit')
  end

  if patch.vco3_active
    expect(interface).to have_css('#vco3_active_button.lit')
  else
    expect(interface).not_to have_css('#vco3_active_button.lit')
  end

  # Lights
  if patch.vco_group == 'one'
    expect(interface).to have_css('#vco_group_one_light.lit')
  else
    expect(interface).not_to have_css('#vco_group_one_light.lit')
  end

  if patch.vco_group == 'two'
    expect(interface).to have_css('#vco_group_two_light.lit')
  else
    expect(interface).not_to have_css('#vco_group_two_light.lit')
  end

  if patch.vco_group == 'three'
    expect(interface).to have_css('#vco_group_three_light.lit')
  else
    expect(interface).not_to have_css('#vco_group_three_light.lit')
  end

  if patch.lfo_target_amp
    expect(interface).to have_css('#lfo_target_amp_light.lit')
  else
    expect(interface).not_to have_css('#lfo_target_amp_light.lit')
  end

  if patch.lfo_target_pitch
    expect(interface).to have_css('#lfo_target_pitch_light.lit')
  else
    expect(interface).not_to have_css('#lfo_target_pitch_light.lit')
  end

  if patch.lfo_target_cutoff
    expect(interface).to have_css('#lfo_target_cutoff_light.lit')
  else
    expect(interface).not_to have_css('#lfo_target_cutoff_light.lit')
  end

  if patch.lfo_wave
    expect(interface).to have_css('#lfo_wave_light.lit')
  else
    expect(interface).not_to have_css('#lfo_wave_light.lit')
  end

  if patch.vco1_wave
    expect(interface).to have_css('#vco1_wave_light.lit')
  else
    expect(interface).not_to have_css('#vco1_wave_light.lit')
  end

  if patch.vco2_wave
    expect(interface).to have_css('#vco2_wave_light.lit')
  else
    expect(interface).not_to have_css('#vco2_wave_light.lit')
  end

  if patch.vco3_wave
    expect(interface).to have_css('#vco3_wave_light.lit')
  else
    expect(interface).not_to have_css('#vco3_wave_light.lit')
  end

  if patch.sustain_on
    expect(interface).to have_css('#sustain_on_light.lit')
  else
    expect(interface).not_to have_css('#sustain_on_light.lit')
  end

  if patch.amp_eg_on
    expect(interface).to have_css('#amp_eg_on_light.lit')
  else
    expect(interface).not_to have_css('#amp_eg_on_light.lit')
  end

  # Content
  return if form
  patch.tags.each do |tag|
    expect(interface).to have_link("##{tag}")
  end
  expect(interface).to have_content(patch.name)
  expect(interface).to have_content(patch.notes)
end

def reflects_keys_patch(patch, options = {})
  interface = options[:interface] || page
  form = options[:form] || false
  # Knobs
  expect(interface).to have_css("#detune[data-midi='#{patch.detune}']")
  expect(interface).to have_css("#portamento[data-midi='#{patch.portamento}']")
  expect(interface).to have_css("#vco_eg_int[data-midi='#{patch.vco_eg_int}']")
  expect(interface).to have_css("#cutoff[data-midi='#{patch.cutoff}']")
  expect(interface).to have_css("#peak[data-midi='#{patch.peak}']")
  expect(interface).to have_css("#vcf_eg_int[data-midi='#{patch.vcf_eg_int}']")
  expect(interface).to have_css("#lfo_rate[data-midi='#{patch.lfo_rate}']")
  expect(interface).to have_css("#lfo_pitch_int[data-midi='#{patch.lfo_pitch_int}']")
  expect(interface).to have_css("#lfo_cutoff_int[data-midi='#{patch.lfo_cutoff_int}']")
  expect(interface).to have_css("#attack[data-midi='#{patch.attack}']")
  expect(interface).to(
    have_css("#decay_release[data-midi='#{patch.decay_release}']")
  )
  expect(interface).to have_css("#sustain[data-midi='#{patch.sustain}']")
  expect(interface).to have_css("#delay_time[data-midi='#{patch.delay_time}']")
  expect(interface).to have_css("#delay_feedback[data-midi='#{patch.delay_feedback}']")
  expect(interface).to have_css("#voice[data-midi='#{patch.voice}']")
  expect(interface).to have_css("#octave[data-midi='#{patch.octave}']")

  # Lights
  if patch.lfo_shape == 'saw'
    expect(interface).to have_css('#lfo_shape_saw_light.lit')
  else
    expect(interface).to have_css('#lfo_shape_saw_light.unlit')
  end

  if patch.lfo_shape == 'triangle'
    expect(interface).to have_css('#lfo_shape_triangle_light.lit')
  else
    expect(interface).to have_css('#lfo_shape_triangle_light.unlit')
  end

  if patch.lfo_shape == 'square'
    expect(interface).to have_css('#lfo_shape_square_light.lit')
  else
    expect(interface).to have_css('#lfo_shape_square_light.unlit')
  end

  # TODO: FROM HERE DOWN IS COPIED FROM BASS SPECS.  CHANGE.
  # Content
  return if form

  patch.tags.each do |tag|
    expect(interface).to have_link("##{tag}")
  end
  expect(interface).to have_content(patch.name)
  expect(interface).to have_content(patch.notes)
end
