# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Synth patch namer', type: :feature, js: true do
  it 'has its own page' do
    visit synth_patch_namer_path

    expect(page).to have_selector('h1', text: 'Synth Patch Namer')
  end

  it 'does not link to itself in the nav bar' do
    with_modified_env FEATURE_ENABLED_PATCH_NAMER: 'true' do
      visit synth_patch_namer_path
      expect(page).to have_link('Synth Patch Namer', href: '#')
    end
  end

  it 'shows a generated patch name' do
    visit synth_patch_namer_path

    find('#synth_name_button').click

    expect(find('#name').text).not_to be_blank
  end

  describe 'creating a bass patch with the generated name' do
    before do
      visit synth_patch_namer_path

      find('#synth_name_button').click

      sleep(1)
    end

    it 'leads to the new bass patch page' do
      click_link 'Name a bass patch »'

      expect(current_path).to eq(new_patch_path)
    end

    it 'prefills the patch name field with generated name' do
      patch_name = find('#name').text

      click_link 'Name a bass patch »'

      expect(find('#patch_name').value).to eq(patch_name)
    end
  end

  describe 'creating a keys patch with the generated name' do
    before do
      visit synth_patch_namer_path

      find('#synth_name_button').click

      sleep(1)
    end

    it 'leads to the new keys patch page' do
      click_link 'Name a keys patch »'

      expect(current_path).to eq(new_keys_patch_path)
    end

    it 'prefills the patch name field with generated name' do
      patch_name = find('#name').text

      click_link 'Name a keys patch »'

      expect(find('#patch_name').value).to eq(patch_name)
    end
  end
end
