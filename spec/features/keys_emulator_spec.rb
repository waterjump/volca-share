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
end
