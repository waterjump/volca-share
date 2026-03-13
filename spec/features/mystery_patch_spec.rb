# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Mystery Patch game', js: true do
  before do
    MysteryPatch.clone_from(build(:keys_patch))
  end

  it 'shows pre-game dialog' do
    visit mystery_patch_path

    expect(page).to have_content('Mystery Patch')
  end

  it 'shows results modal and stores resultsData cookie after a minimal run-through' do
    visit mystery_patch_path

    click_button 'Got it'
    expect(page).to have_no_css('#pre-game-modal.in', visible: :all)
    click_button 'Hear Mystery Patch'
    click_button "I'm Done"
    click_button "Yes, I'm done"

    expect(page).to have_css('#results-modal.in', visible: :all)
    expect(page).to have_css('#overall-score', text: 'Total score:', visible: :all)
    expect(page).to have_css('#overall-score', visible: true)
    expect(page.evaluate_script('document.cookie')).to include('resultsData=')
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
