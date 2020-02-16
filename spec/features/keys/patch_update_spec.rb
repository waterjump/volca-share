# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Updating a keys patch', js: true do
  let!(:user) { FactoryBot.create(:user) }
  let!(:patch_to_update) do
    user.keys_patches.create!(
      attributes_for(
        :keys_patch,
        name: 'Original patch name',
        detune: 127,
        voice: 70, # Fifth
        lfo_trigger_sync: false
      )
    )
  end

  describe 'the form to edit patch' do
    it 'reflects the keys patch' do
      login
      visit edit_user_keys_patch_path(user.slug, patch_to_update.slug)

      reflects_keys_patch(patch_to_update, form: true)
      keys_js_knobs_rotated(patch_to_update)
    end
  end

  describe 'the show page after updating' do
    it 'reflects updated patch values' do
      login
      visit edit_user_keys_patch_path(user.slug, patch_to_update.slug)
      original_patch_attributes = patch_to_update.attributes
      new_name = 'Updated patch name :-]'

      # Adjust form
      fill_in 'patch[name]', with: new_name
      page.find('#detune').drag_to(page.find('#vco_eg_int'))
      page.find('#voice').drag_to(page.find('#octave'))
      page.find('#lfo_trigger_sync_light').click

      click_button 'Save'

      updated_patch_attributes = patch_to_update.reload.attributes

      expect(updated_patch_attributes['name']).not_to(
        eq(original_patch_attributes['name'])
      )
      expect(updated_patch_attributes['detune']).not_to(
        eq(original_patch_attributes['detune'])
      )
      expect(updated_patch_attributes['voice']).not_to(
        eq(original_patch_attributes['voice'])
      )
      expect(updated_patch_attributes['lfo_trigger_sync']).not_to(
        eq(original_patch_attributes['lfo_trigger_sync'])
      )

      changed_fields =
        %w(detune voice name lfo_trigger_sync slug updated_at created_at)

      expect(updated_patch_attributes.except(*changed_fields)).to(
        eq(original_patch_attributes.except(*changed_fields))
      )

      reflects_keys_patch(patch_to_update)
      keys_js_knobs_rotated(patch_to_update)
    end
  end
end
