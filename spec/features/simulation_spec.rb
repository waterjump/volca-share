# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Volca Bass Emulation', type: :feature  do
  it 'has its own page' do
    visit new_simulation_path

    expect(page).to have_content('Simulator')
    expect(page).to have_css('.volca.bass.simulation')
  end
end
