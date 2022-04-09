# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Volca Bass Emulator', type: :feature  do
  it 'has its own page' do
    visit bass_emulator_path

    expect(page).to have_content('Emulator')
    expect(page).to have_css('.volca.bass.emulator')
  end

  context 'when query string parameters are passed', js: true do
    let(:patch) { VolcaShare::PatchViewModel.wrap(create(:patch)) }

    it 'reflects the query string parameters' do
      visit bass_emulator_path(patch.emulator_query_string)

      reflects_emulator_patch(patch)
    end

    it 'shows volume knob all the way up' do
      visit bass_emulator_path(patch.emulator_query_string)

      expect(page.find('span.volume', visible: false).text).to(
        eq(rotation_from_midi(127))
      )
    end

    context 'when mobile version link is clicked' do
      it 'does not reset the patch' do
        visit bass_emulator_path(patch.emulator_query_string)
        click_link('mobile version')

        expect(page).to(
          have_current_path(
            bass_emulator_path(patch.emulator_query_string)
          )
        )

        reflects_emulator_patch(patch)
        expect(page).to have_link('Back to desktop mode')
      end
    end
  end

  def reflects_emulator_patch(patch, options = {})
    expect(page.find('span.attack', visible: false).text).to(
      eq(rotation_from_midi(patch.attack).to_s)
    )
    expect(page.find('span.decay_release', visible: false).text).to(
      eq(rotation_from_midi(patch.decay_release).to_s)
    )
    expect(page.find('span.cutoff_eg_int', visible: false).text).to(
      eq(rotation_from_midi(patch.cutoff_eg_int).to_s)
    )
    expect(page.find('span.octave', visible: false).text).to(
      eq(rotation_from_midi(closest_octave_value(patch.octave)).to_s)
    )
    expect(page.find('span.peak', visible: false).text).to(
      eq(rotation_from_midi(patch.peak).to_s)
    )
    expect(page.find('span.cutoff', visible: false).text).to(
      eq(rotation_from_midi(patch.cutoff).to_s)
    )
    expect(page.find('span.lfo_rate', visible: false).text).to(
      eq(rotation_from_midi(patch.lfo_rate).to_s)
    )
    expect(page.find('span.lfo_int', visible: false).text).to(
      eq(rotation_from_midi(patch.lfo_int).to_s)
    )
    expect(page.find('span.vco1_pitch', visible: false).text).to(
      eq(rotation_from_midi(patch.vco1_pitch).to_s)
    )
    expect(page.find('span.vco2_pitch', visible: false).text).to(
      eq(rotation_from_midi(patch.vco2_pitch).to_s)
    )
    expect(page.find('span.vco3_pitch', visible: false).text).to(
      eq(rotation_from_midi(patch.vco3_pitch).to_s)
    )

    expect(page).to have_css('#vco1_pitch.lit') if patch.vco1_active
    expect(page).to have_css('#vco2_pitch.lit') if patch.vco2_active
    expect(page).to have_css('#vco3_pitch.lit') if patch.vco3_active
    expect(page).not_to have_css('#vco1_pitch.lit') unless patch.vco1_active
    expect(page).not_to have_css('#vco2_pitch.lit') unless patch.vco2_active
    expect(page).not_to have_css('#vco3_pitch.lit') unless patch.vco3_active

    # Buttons
    if patch.vco1_active
      expect(page).to have_css('#vco1_active_button.lit')
    else
      expect(page).not_to have_css('#vco1_active_button.lit')
    end

    if patch.vco2_active
      expect(page).to have_css('#vco2_active_button.lit')
    else
      expect(page).not_to have_css('#vco2_active_button.lit')
    end

    if patch.vco3_active
      expect(page).to have_css('#vco3_active_button.lit')
    else
      expect(page).not_to have_css('#vco3_active_button.lit')
    end

    # Lights
    if patch.vco_group == 'one'
      expect(page).to have_css('#vco_group_one_light.lit')
    else
      expect(page).not_to have_css('#vco_group_one_light.lit')
    end

    if patch.vco_group == 'two'
      expect(page).to have_css('#vco_group_two_light.lit')
    else
      expect(page).not_to have_css('#vco_group_two_light.lit')
    end

    if patch.vco_group == 'three'
      expect(page).to have_css('#vco_group_three_light.lit')
    else
      expect(page).not_to have_css('#vco_group_three_light.lit')
    end

    if patch.lfo_target_amp
      expect(page).to have_css('#lfo_target_amp_light.lit')
    else
      expect(page).not_to have_css('#lfo_target_amp_light.lit')
    end

    if patch.lfo_target_pitch
      expect(page).to have_css('#lfo_target_pitch_light.lit')
    else
      expect(page).not_to have_css('#lfo_target_pitch_light.lit')
    end

    if patch.lfo_target_cutoff
      expect(page).to have_css('#lfo_target_cutoff_light.lit')
    else
      expect(page).not_to have_css('#lfo_target_cutoff_light.lit')
    end

    if patch.lfo_wave
      expect(page).to have_css('#lfo_wave_light.lit')
    else
      expect(page).not_to have_css('#lfo_wave_light.lit')
    end

    if patch.vco1_wave
      expect(page).to have_css('#vco1_wave_light.lit')
    else
      expect(page).not_to have_css('#vco1_wave_light.lit')
    end

    if patch.vco2_wave
      expect(page).to have_css('#vco2_wave_light.lit')
    else
      expect(page).not_to have_css('#vco2_wave_light.lit')
    end

    if patch.vco3_wave
      expect(page).to have_css('#vco3_wave_light.lit')
    else
      expect(page).not_to have_css('#vco3_wave_light.lit')
    end

    if patch.sustain_on
      expect(page).to have_css('#sustain_on_light.lit')
    else
      expect(page).not_to have_css('#sustain_on_light.lit')
    end

    if patch.amp_eg_on
      expect(page).to have_css('#amp_eg_on_light.lit')
    else
      expect(page).not_to have_css('#amp_eg_on_light.lit')
    end
  end

  def closest_octave_value(midi_value)
    case midi_value
    when 0..21
      0
    when 22..43
      33
    when 44..65
      55
    when 66..87
      77
    when 88..109
      110
    when 110..127
      127
    end
  end

end
