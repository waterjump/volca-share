# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Deleting a keys patch', type: :feature, js: true do
  let(:user) { create(:user) }

  context 'when user is patch author' do
    it 'deletes the patch' do
      patch = user.keys_patches.create(attributes_for(:keys_patch))

      login
      visit user_keys_patch_path(user.slug, patch.slug)
      click_button('Delete')
      user.reload

      expect(user.patches.count).to eq(0)
      expect(Keys::Patch.where(id: patch.id).count).to eq(0)
    end
  end

  context 'when user is not patch author' do
    it 'is not possible' do
      patch = user.keys_patches.create(attributes_for(:keys_patch))
      user_2 = create(:user)

      login(user_2)

      visit user_keys_patch_path(user.slug, patch.slug)
      expect(page).not_to have_button('Delete')
    end

    context 'when patch is anonymous' do
      it 'is not possible' do
        patch = create(:keys_patch)

        login
        visit keys_patch_path(patch.id)

        expect(page).not_to have_button('Delete')
      end
    end
  end

  context 'when user is anonymous' do
    it 'is not possible' do
      patch = user.keys_patches.create(attributes_for(:keys_patch))

      visit user_keys_patch_path(patch.user.slug, patch.slug)

      expect(page).not_to have_button('Delete')
    end

    context 'when patch is anonymous' do
      it 'is not possible' do
        patch = create(:keys_patch)

        visit keys_patch_path(patch.id)

        expect(page).not_to have_button('Delete')
      end
    end
  end
end

