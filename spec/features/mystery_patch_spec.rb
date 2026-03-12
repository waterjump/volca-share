# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Mystery Patch game', js: true do
  it 'shows pre-game dialog' do
    visit mystery_patch_path

    expect(page).to have_content('Mystery Patch')
  end

  context 'when mystery patch callout modal feature is enabled' do
    around do |example|
      with_modified_env FEATURE_ENABLED_MYSTERY_PATCH_MODAL: 'true' do
        example.run
      end
    end

    it 'does not show the mystery patch callout modal on the mystery patch path' do
      page.driver.browser.manage.delete_cookie('mysteryPatchModalSeen')

      visit mystery_patch_path

      expect(page).not_to have_css('#mystery-patch-callout-modal', visible: :all)
    end
  end
end
