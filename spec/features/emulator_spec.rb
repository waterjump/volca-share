# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Volca Bass Emulator', type: :feature, js: true  do
  let (:query_string) { Hash.new }

  before do
    visit bass_emulator_path(query_string)
  end

  it 'has its own page' do
    expect(page).to have_content('Emulator')
    expect(page).to have_css('.volca.bass.emulator')
  end

  context 'when query string parameters are passed'do
    let(:patch) { VolcaShare::PatchViewModel.wrap(create(:patch)) }
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
            bass_emulator_path(patch.emulator_query_string)
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

  describe 'sequncer' do
    describe 'notes' do
      it 'can be changed' do
        find('#toggle-sequences').click

        find('#patch_sequences_attributes_0_step_1_note_display')
          .drag_to(seq_form_light(0, 1, 'slide'))

        expect(find('#patch_sequences_attributes_0_step_1_note_display')).to(
          have_text('E2')
        )
      end
    end
  end

  describe 'sequence clearing' do
    describe 'clear part button' do
      it 'resets sequence notes' do
        find('#toggle-sequences').click

        find('#patch_sequences_attributes_0_step_1_note_display')
          .drag_to(seq_form_light(0, 1, 'slide'))

        find('#clear-part').click

        expect(find('#patch_sequences_attributes_0_step_1_note_display')).to(
          have_text('C3')
        )

        step_starting_note_data_attr  =
          evaluate_script(
            "$('#patch_sequences_attributes_0_step_1_note_display').data('starting-note')"
          )

        expect(step_starting_note_data_attr).to eq 60
      end
    end
  end
end
