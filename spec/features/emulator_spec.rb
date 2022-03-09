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

      reflects_patch(patch, skip_midi: true, form: true)
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

        reflects_patch(patch, skip_midi: true, form: true)
        expect(page).to have_link('Back to desktop mode')
      end
    end
  end
end
