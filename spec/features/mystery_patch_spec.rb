# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Mystery Patch game', js: true do
  it 'shows pre-game dialog' do
    visit mystery_patch_path

    expect(page).to have_content('Mystery Patch')
  end
end
