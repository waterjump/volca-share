# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Synth patch namer', type: :feature, js: true do
  it 'has its own page' do
    visit synth_patch_namer_path

    expect(page).to have_selector('h1', text: 'Synth Patch Namer')
  end

  it 'shows a generated patch name' do
    visit synth_patch_namer_path

    click_link 'Gimme a patch name'

    expect(find('#name').text).not_to be_blank
  end

  describe 'creating a bass patch with the generated name' do
    before do
      visit synth_patch_namer_path

      click_link 'Gimme a patch name'
    end

    it 'leads to the new bass patch page' do
      click_link 'Make a bass patch with this name'

      expect(current_path).to eq(new_patch_path)
    end

    it 'prefills the patch name field with generated name' do
      patch_name = find('#name').text

      click_link 'Make a bass patch with this name'

      expect(find('#patch_name').value).to eq(patch_name)
    end
  end
end
