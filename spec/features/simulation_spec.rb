# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Volca Bass Emulation', type: :feature  do
  it 'has its own page' do
    visit new_simulation_path

    save_and_open_page
    expect(page).to have_content('Simulation')
    expect(page).to have_css('.volca.bass')
  end
end
