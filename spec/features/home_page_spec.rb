require 'rails_helper'

RSpec.feature 'the home page', type: :feature, js: true do
  before(:each) { visit root_path }

  scenario 'user can access homepage' do
    expect(page.status_code).to eq(200)
  end

  scenario 'user see relevant information' do
    expect(page).to have_selector('h1', text: 'Patches')
  end

  scenario 'header is shown' do
    expect(page).to have_content(/VolcaShare/i)
    expect(page).to have_content(/About/i)
    expect(page).to have_content(/New Patch/i)
  end

  scenario 'footer is shown' do
    expect(page).to have_content(/Sean Barrett/i)
  end
end
