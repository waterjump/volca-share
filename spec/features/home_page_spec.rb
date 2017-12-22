require 'rails_helper'

RSpec.describe 'Home page', type: :feature, js: true do
  before(:each) { visit root_path }

  it 'shows h1' do
    expect(page).to have_selector('h1', text: 'Patches')
  end

  it 'shows header' do
    expect(page).to have_link('VolcaShare')
    expect(page).to have_link('About')
    expect(page).to have_link('New Patch')
    expect(page).to have_link('Log in')
    expect(page).to have_link('Sign Up')
  end

  it 'shows footer' do
    expect(page).to have_content(/Sean Barrett/i)
  end
end
