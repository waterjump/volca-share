# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Volca Bass Emulator', type: :feature  do
  it 'has its own page' do
    visit bass_emulator_path

    expect(page).to have_content('Emulator')
    expect(page).to have_css('.volca.bass.emulator')
  end
end
