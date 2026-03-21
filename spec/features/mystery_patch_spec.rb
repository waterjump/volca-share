# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Mystery Patch game', js: true do
  let!(:mystery_patch) { create(:mystery_patch) }

  it 'shows pre-game dialog' do
    visit mystery_patch_path

    expect(page).to have_content("Mystery Patch \##{mystery_patch.number}")
  end

  it 'shows results modal and stores resultsData cookie after a minimal run-through' do
    visit mystery_patch_path

    expect(page).to have_no_css('#request-hint', visible: true)
    click_button 'Got it'
    expect(page).to have_no_css('#pre-game-modal.in', visible: :all)
    click_button 'Hear Mystery Patch'
    expect(page).to have_css('#request-hint', visible: true)
    click_button "I'm Done"
    click_button "Yes, I'm done"

    expect(page).to have_css('#results-modal.in', visible: :all)
    expect(page).to have_css('#overall-score', text: 'Total score:', visible: :all)
    expect(page).to have_css('#overall-score', visible: true)
    expect(page).to have_no_css('#request-hint', visible: true)
    expect(page.evaluate_script('document.cookie')).to include('resultsData=')
  end

  it 'requests a hint when the bulb icon is clicked' do
    visit mystery_patch_path

    click_button 'Got it'
    click_button 'Hear Mystery Patch'

    hint_icon = find('#request-hint', visible: true)
    expect(hint_icon['title']).to include('Request a hint')

    hint_icon.click

    expect(page).to have_css('#request-hint[title*="1 left"]', visible: true)
  end

  it 'places hint emojis after the corresponding parameter squares in share text' do
    visit mystery_patch_path

    # Spoof results cookie
    page.execute_script(<<~JS)
      document.cookie = 'resultsData=' + encodeURIComponent(JSON.stringify({
        mysteryPatchId: "#{mystery_patch.id}",
        timeSubmitted: Math.floor(Date.now() / 1000),
        hintsUsed: 2,
        hintedParams: ['attack', 'cutoff'],
        results: {
          total_score: 88.5,
          parameter_scores: {
            attack: [64, 64, 0, 100.0],
            cutoff: [32, 96, 64, 49.61]
          }
        }
      })) + '; path=/';
    JS

    visit mystery_patch_path

    expect(page).to have_css('#results-modal.in', visible: :all)
    expect(find('#share-text', visible: :all).value).to include("🟩💡🟥💡")
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
