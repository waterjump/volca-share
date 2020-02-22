# frozen_string_literal: true

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

  fill_in 'patch[tags]', with: patch.tags.join(', '), visible: false
  return if anon
  check 'patch[secret]' if patch.secret?
  fill_in 'patch[audio_sample]', with: patch.audio_sample
end

def keys_js_knobs_rotated(patch, options = {})
  interface = page

  expect(interface.find('span.detune', visible: false).text).to(
    eq(rotation_from_midi(patch.detune).to_s)
  )
  expect(interface.find('span.portamento', visible: false).text).to(
    eq(rotation_from_midi(patch.portamento).to_s)
  )
  expect(interface.find('span.vco_eg_int', visible: false).text).to(
    eq(rotation_from_midi(patch.vco_eg_int).to_s)
  )
  expect(interface.find('span.cutoff', visible: false).text).to(
    eq(rotation_from_midi(patch.cutoff).to_s)
  )
  expect(interface.find('span.peak', visible: false).text).to(
    eq(rotation_from_midi(patch.peak).to_s)
  )
  expect(interface.find('span.vcf_eg_int', visible: false).text).to(
    eq(rotation_from_midi(patch.vcf_eg_int).to_s)
  )
  expect(interface.find('span.lfo_rate', visible: false).text).to(
    eq(rotation_from_midi(patch.lfo_rate).to_s)
  )
  expect(interface.find('span.lfo_pitch_int', visible: false).text).to(
    eq(rotation_from_midi(patch.lfo_pitch_int).to_s)
  )
  expect(interface.find('span.lfo_cutoff_int', visible: false).text).to(
    eq(rotation_from_midi(patch.lfo_cutoff_int).to_s)
  )
  expect(interface.find('span.attack', visible: false).text).to(
    eq(rotation_from_midi(patch.attack).to_s)
  )
  expect(interface.find('span.decay_release', visible: false).text).to(
    eq(rotation_from_midi(patch.decay_release).to_s)
  )
 expect(interface.find('span.sustain', visible: false).text).to(
    eq(rotation_from_midi(patch.sustain).to_s)
  )
  expect(interface.find('span.voice', visible: false).text).to(
    eq(snap_knob_rotation_from_midi(patch.voice).to_s)
  )
  expect(interface.find('span.octave', visible: false).text).to(
    eq(snap_knob_rotation_from_midi(patch.octave).to_s)
  )
  expect(interface.find('span.delay_time', visible: false).text).to(
    eq(rotation_from_midi(patch.delay_time).to_s)
  )
  expect(interface.find('span.delay_feedback', visible: false).text).to(
    eq(rotation_from_midi(patch.delay_feedback).to_s)
  )
end

def snap_knob_rotation_from_midi(midi)
  midi_to_degree_map = {
    10 => -90,
    30 => -60,
    50 => -30,
    70 => 0,
    100 => 30,
    120 => 60
  }

  midi_to_degree_map[midi]
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

  if patch.lfo_trigger_sync
    expect(interface).to have_css('#lfo_trigger_sync_light.lit')
  else
    expect(interface).to have_css('#lfo_trigger_sync_light.unlit')
  end

  if patch.tempo_delay
    expect(interface).to have_css('#tempo_delay_light.lit')
  else
    expect(interface).to have_css('#tempo_delay_light.unlit')
  end

  if patch.step_trigger
    expect(interface).to have_css('#step_trigger_light.lit')
  else
    expect(interface).to have_css('#step_trigger_light.unlit')
  end

  if patch.audio_sample.present?
    expect(interface).to have_css('.sample')
  end

  # Content
  return if form

  patch.tags.each do |tag|
    expect(interface).to have_link("##{tag}")
  end
  expect(interface).to have_content(patch.name)
  expect(interface).to have_content(patch.notes)
end
