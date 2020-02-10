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
      click_button 'Save'
    end

    it 'persists patch' do
      expect(Keys::Patch.first.attributes).to include(
        dummy_patch.attributes.except('_id')
      )
    end

    it 'directs user to user patch show page' do
      expect(current_path).to(
        eq(user_keys_patch_path(user.slug, Keys::Patch.first.slug))
      )
    end
  end

  context 'when user is not logged in' do
    before do
      visit new_keys_patch_path
      fill_out_keys_patch_form(dummy_patch)
      click_button 'Save'
    end

    it 'persists patch' do
      expect(Keys::Patch.first.attributes).to include(
        dummy_patch.attributes.except('_id')
      )
    end

    it 'directs user to user patch show page' do
      expect(current_path).to eq(keys_patch_path(Keys::Patch.first.id))
    end
  end
end
