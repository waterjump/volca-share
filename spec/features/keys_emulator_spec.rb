# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Volca Keys Emulator', type: :feature, js: true  do
  let (:query_string) { Hash.new }

  before do
    visit keys_emulator_path(query_string)
  end

  it 'has its own page' do
    expect(page).to have_content('Emulator')
    expect(page).to have_css('.volca.keys.emulator')
  end

  context 'when closing accordion display' do
    it 'remains closed on next page load' do
      expect(page).to have_css('#desktop-instructions', visible: true)
      find('.accordion-header', text: 'Usage').click
      expect(page).not_to have_css('#desktop-instructions', visible: true)

      visit keys_emulator_path
      expect(page).not_to have_css('#desktop-instructions', visible: true)
    end
  end

  context 'when query string parameters are passed' do
    let(:patch) { VolcaShare::Keys::PatchViewModel.wrap(create(:keys_patch)) }
    let(:query_string) { patch.emulator_query_string }

    it 'reflects the query string parameters' do
      reflects_emulator_patch(patch)
    end

    it 'shows volume knob all the way up' do
      expect(page.find('span.volume', visible: false).text).to(
        eq(rotation_from_midi(127))
      )
    end

    context 'when mobile version link is clicked' do
      it 'does not reset the patch' do
        click_link('mobile version')

        expect(page).to(
          have_current_path(
            keys_emulator_path(patch.emulator_query_string)
          )
        )

        reflects_emulator_patch(patch)
        expect(page).to have_link('Back to desktop mode')
      end
    end
  end

  describe 'accordion section', :js do
    it 'can be collapsed' do
      expect(page).to have_css('#desktop-instructions', visible: true)

      within first('.accordion-header') do
        find('.collapse-toggle').click
      end

      expect(page).not_to have_css('#desktop-instructions', visible: true)

      first('.accordion-header').click

      expect(page).to have_css('#desktop-instructions', visible: true)
    end
  end

  # ========= helper methods ==========

  def reflects_emulator_patch(patch, options = {})
    expect(page.find('span.voice', visible: false).text).to(
      eq(snap_knob_rotation_from_midi(patch.voice).to_s)
    )
    expect(page.find('span.octave', visible: false).text).to(
      eq(snap_knob_rotation_from_midi(patch.octave).to_s)
    )
    expect(page.find('span.detune', visible: false).text).to(
      eq(rotation_from_midi(patch.detune).to_s)
    )
    expect(page.find('span.portamento', visible: false).text).to(
      eq(rotation_from_midi(patch.portamento).to_s)
    )
    expect(page.find('span.vco_eg_int', visible: false).text).to(
      eq(rotation_from_midi(patch.vco_eg_int).to_s)
    )
    expect(page.find('span.cutoff', visible: false).text).to(
      eq(rotation_from_midi(patch.cutoff).to_s)
    )
    expect(page.find('span.peak', visible: false).text).to(
      eq(rotation_from_midi(patch.peak).to_s)
    )
    expect(page.find('span.vcf_eg_int', visible: false).text).to(
      eq(rotation_from_midi(patch.vcf_eg_int).to_s)
    )
    expect(page.find('span.lfo_rate', visible: false).text).to(
      eq(rotation_from_midi(patch.lfo_rate).to_s)
    )
    expect(page.find('span.lfo_pitch_int', visible: false).text).to(
      eq(rotation_from_midi(patch.lfo_pitch_int).to_s)
    )
    expect(page.find('span.lfo_cutoff_int', visible: false).text).to(
      eq(rotation_from_midi(patch.lfo_cutoff_int).to_s)
    )
    expect(page.find('span.attack', visible: false).text).to(
      eq(rotation_from_midi(patch.attack).to_s)
    )
    expect(page.find('span.decay_release', visible: false).text).to(
      eq(rotation_from_midi(patch.decay_release).to_s)
    )
    expect(page.find('span.sustain', visible: false).text).to(
      eq(rotation_from_midi(patch.sustain).to_s)
    )
    expect(page.find('span.delay_time', visible: false).text).to(
      eq(rotation_from_midi(patch.delay_time).to_s)
    )
    expect(page.find('span.delay_feedback', visible: false).text).to(
      eq(rotation_from_midi(patch.delay_feedback).to_s)
    )

    case patch.lfo_shape
    when 'sawtooth'
      expect(page).to have_css('#lfo_shape_saw_light.lit')
    when 'square'
      expect(page).to have_css('#lfo_shape_square_light.lit')
    when 'triangle'
      expect(page).to have_css('#lfo_shape_triangle_light.lit')
    end

    if (patch.lfo_trigger_sync)
      expect(page).to have_css('#lfo_trigger_sync_light.lit')
    else
      expect(page).not_to have_css('#lfo_trigger_sync_light.lit')
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
