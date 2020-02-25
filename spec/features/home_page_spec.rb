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

  it 'shows footer' do
    expect(page).to have_css('.footer')
  end
end
