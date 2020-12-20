# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Synth patch namer', type: :feature do
  it 'has its own page' do
    visit synth_patch_namer_path

    expect(page).to have_selector('h1', text: 'Synth Patch Namer')
  end

  it 'shows a generated patch name', js: true do
    visit synth_patch_namer_path

    click_link 'Gimme a patch name'

    expect(find('#name').text).not_to be_blank
  end
end
