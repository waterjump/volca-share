# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a keys patch', type: :feature, js: true do
  let(:user) { FactoryBot.create(:user) }
  let(:dummy_patch) do
    FactoryBot.build(
      :keys_patch,
      name: 'My Cool Keys Patch',
      notes: 'This keys patch is cool.'
    )
  end

  context 'when user is logged in' do
    before do
      login
      visit new_keys_patch_path
      fill_out_keys_patch_form(dummy_patch)
    end

    it 'persists patch' do
      click_button 'Save'

      expect(Keys::Patch.first.attributes).to include(
        dummy_patch.attributes.except('_id')
      )
    end

    it 'directs user to user patch show page' do
      click_button 'Save'

      expect(current_path).to(
        eq(user_keys_patch_path(user.slug, Keys::Patch.first.slug))
      )
    end

    it 'reflects the keys patch' do
      click_button 'Save'

      reflects_keys_patch(dummy_patch)
      keys_js_knobs_rotated(dummy_patch)
    end

    describe 'audio samples' do
      it 'accepts valid soundcloud URLS' do
        fill_in 'patch[audio_sample]',
                with: 'https://soundcloud.com/69bot/take-it-to-the-streets'
        click_button 'Save'
        expect(page.body).to have_content('Patch saved successfully.')
      end

      it 'accepts valid youtube URLS' do
        fill_in 'patch[audio_sample]',
                with: 'https://youtube.com/watch?v=GF60Iuh643I'
        click_button 'Save'
        expect(page.body).to have_content('Patch saved successfully.')
      end

      it 'accepts valid freesound URLS' do
        fill_in 'patch[audio_sample]',
                with: 'https://freesound.org/people/volcashare/sounds/123456'
        click_button 'Save'
        expect(page.body).to have_content('Patch saved successfully.')
      end

      it 'rejects invalid URLS' do
        fill_in 'patch[audio_sample]', with: 'https://foo.edu/69bot/shallow'
        click_button 'Save'
        expect(page).to have_content(
          'Audio sample needs to be direct SoundCloud, Freesound or YouTube link.'
        )
      end
    end
  end

  context 'when user is not logged in' do
    let(:dummy_patch) do
      FactoryBot.build(
        :keys_patch,
        name: 'My Cool Keys Patch',
        notes: 'This keys patch is cool.',
        audio_sample: nil
      )
    end

    before do
      visit new_keys_patch_path
      fill_out_keys_patch_form(dummy_patch, true)
      click_button 'Save'
    end

    it 'persists patch' do
      expect(Keys::Patch.first.attributes).to include(
        dummy_patch.attributes.except('_id', 'audio_sample')
      )
    end

    it 'directs user to user patch show page' do
      expect(current_path).to eq(keys_patch_path(Keys::Patch.first.id))
    end

    it 'reflects the keys patch' do
      reflects_keys_patch(dummy_patch)
      keys_js_knobs_rotated(dummy_patch)
    end
  end

  describe 'initial form situation' do
    it 'shows knobs turned to default values' do
      visit new_keys_patch_path
      keys_js_knobs_rotated(Keys::Patch.new)
    end
  end
end
