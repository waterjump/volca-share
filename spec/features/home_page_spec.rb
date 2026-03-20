# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Home page', type: :feature, js: true do
  before { visit root_path }

  it 'shows h1' do
    expect(page).to(
      have_selector('h1', text: 'Share your patches with the world')
    )
  end

  it 'has a title' do
    expect(page.title).to(
      eq('Share patches for Korg Volca Bass and Korg Volca Keys | VolcaShare')
    )
  end

  it 'shows header' do
    expect(page).to have_link('VolcaShare')
    expect(page).to have_link('Bass')
    expect(page).to have_link('Keys')
    expect(page).to have_link('Log in')
    expect(page).to have_link('Sign Up')
  end

  context 'when patch namer feature is enabled' do
    around do |example|
      with_modified_env FEATURE_ENABLED_PATCH_NAMER: 'true' do
        example.run
      end
    end

    it 'shows link to patch namer in header' do
      expect(page).to have_link('Synth Patch Namer')
    end
  end

  context 'when patch namer feature is not enabled' do
    around do |example|
      with_modified_env FEATURE_ENABLED_PATCH_NAMER: 'false' do
        example.run
      end
    end

    it 'does not show link to patch namer in header' do
      expect(page).not_to have_link('Synth Patch Namer')
    end
  end

  context 'when mystery patch callout modal feature is enabled' do
    around do |example|
      with_modified_env FEATURE_ENABLED_MYSTERY_PATCH_MODAL: 'true' do
        example.run
      end
    end

    it 'shows the mystery patch callout modal' do
      page.driver.browser.manage.delete_cookie('mysteryPatchModalSeen')
      visit current_path

      expect(page).to have_css('#mystery-patch-callout-modal', visible: :all)
    end
  end

  context 'when mystery patch callout modal feature is not enabled' do
    around do |example|
      with_modified_env FEATURE_ENABLED_MYSTERY_PATCH_MODAL: 'false' do
        example.run
      end
    end

    it 'does not show the mystery patch callout modal' do
      visit current_path

      expect(page).not_to have_css('#mystery-patch-callout-modal', visible: :all)
    end
  end

  it 'shows link to bass emulator' do
    click_link('Bass')
    expect(page).to have_link('Emulator')
  end

  context 'when mystery patch feature is enabled' do
    around do |example|
      with_modified_env FEATURE_ENABLED_MYSTERY_PATCH: 'true' do
        example.run
      end
    end

    it 'shows link to Mystery Patch in top nav' do
      expect(page).to have_link('Play Mystery Patch')
    end

    context 'when user has played today' do
      let(:cookie_value) do
        {
          mysteryPatchId: mystery_patch.id.to_s,
          timeSubmitted: 1772990357,
          results: {
            total_score: 54.66,
          }
        }.to_json
      end

      let(:mystery_patch) do
        MysteryPatch.generate_random.tap(&:save).reload
      end

      before do
        page.driver.browser.manage.add_cookie(name: 'resultsData', value: cookie_value)
      end

      it 'shows overall score in menu callout' do
        visit current_path
        expect(page).to have_css('.speech.left', text: '54.66%')
      end
    end

    context 'when user has played but theres a newer mystery patch' do
      let(:cookie_value) do
        {
          mysteryPatchId: mystery_patch.id.to_s, # '69ad1088b6951a0002757a78',
          timeSubmitted: 1772990357,
          results: {
            total_score: 54.66,
          }
        }.to_json
      end

      let(:mystery_patch) do
        MysteryPatch.generate_random.tap(&:save).reload
      end

      before do
        page.driver.browser.manage.add_cookie(name: 'resultsData', value: cookie_value)
      end

      it 'shows overall score in menu callout' do
        # create newer mystery patch
        MysteryPatch.generate_random.save

        visit current_path
        expect(page).to have_css('.speech.left', text: 'NEW')
      end
    end

    context 'when user has not played' do
      # No cookie setting
      it 'shows default callout' do
        expect(page).to have_css('.speech.left', text: 'NEW')
      end
    end
  end

  context 'when mystery patch feature is disabled' do
    around do |example|
      with_modified_env FEATURE_ENABLED_MYSTERY_PATCH: 'false' do
        example.run
      end
    end

    it 'does not show link in top nav' do
      expect(page).not_to have_link('Play Mystery Patch')
    end
  end

  it 'show three top patches from volca bass' do
    create_list(:user_patch, 3)
    visit root_path

    expect(page).to have_css('.patch', count: 3)
  end

  it 'show three top patches from volca keys'

  it 'does not show emulation controls on home page patch cards' do
    create(:user_patch, name: 'Bass Home Patch')
    create(:user_keys_patch, name: 'Keys Home Patch')

    visit root_path

    expect(page).not_to have_css('.bass-emulate-toggle')
    expect(page).not_to have_css('.keys-emulate-toggle')
  end

  it 'shows footer' do
    expect(page).to have_css('.footer')
  end

  it 'shows link to discord server' do
    expect(page).to have_link('Discord')
  end
end
