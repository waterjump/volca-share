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

  describe 'octave parameter' do
    it 'can be set using click and drag' do
      page.find('#octave').drag_to(find('#voice'))
      find('#permalink').click
      expect(page.current_url).to include('octave=120')
    end
  end

  describe 'dragging knob twice' do
    it 'is cumulative' do
      page.find('#peak').drag_to(find('#cutoff'))
      peak_knob_midi_value = evaluate_script(
        "$('#peak').data('midi')"
      )
      expect(peak_knob_midi_value).to eq(26)

      page.find('#peak').drag_to(find('#cutoff'))
      peak_knob_midi_value = evaluate_script(
        "$('#peak').data('midi')"
      )
      expect(peak_knob_midi_value).to eq(53)
    end
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
      reflects_keys_emulator_patch(patch)
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

        reflects_keys_emulator_patch(patch)
        expect(page).to have_link('Back to desktop mode')
      end
    end
  end

  describe 'accordion section', :js do
    it 'can be collapsed' do
      expect(page).to have_css('#desktop-instructions', visible: true)

      first('.collapse-toggle').click

      expect(page).not_to have_css('#desktop-instructions', visible: true)

      first('.collapse-toggle').click

      expect(page).to have_css('#desktop-instructions', visible: true)
    end
  end

  describe 'MIDI input' do
    context 'when midi input is supported' do
      before do
        page.execute_script(File.read(Rails.root.join(mock_file)))
        page.execute_script('VS.midiIn.init();')
      end

      context 'when a midi device is available' do
        let(:mock_file) { 'spec/support/web_midi_mock.js' }

        it 'shows the midi input accordion section' do
          expect(page).to have_css('#midi-input', visible: true)
        end
      end

      context 'when no midi device is available' do
        let(:mock_file) { 'spec/support/web_midi_mock_no_device.js' }

        it 'does not show the midi input accordion section' do
          expect(page).not_to have_css('#midi-input', visible: true)
        end
      end
    end

    context 'when midi input is not supported' do
      it 'does not show the midi input accordion section' do
        expect(page).not_to have_css('#midi-input', visible: true)
      end
    end
  end
end
