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

  it 'shows link to bass emulator' do
    click_link('Bass')
    expect(page).to have_link('Emulator')
  end

  it 'show three top patches from volca bass' do
    create_list(:user_patch, 3)
    visit root_path

    expect(page).to have_css('.patch', count: 3)
  end

  it 'show three top patches from volca keys'

  it 'shows footer' do
    expect(page).to have_css('.footer')
  end
end
