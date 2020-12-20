# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Synth patch namer', type: :feature do
  it 'has its own page' do
    visit synth_patch_namer_path

    expect(page).to have_selector('h1', text: 'Synth Patch Namer')
  end

  xit 'shows a generated patch name' do
    visit synth_patch_namer_path

    click 'Gimme a patch name'
    within '#name' do
      expect(page).to have_content
    end
  end
end
