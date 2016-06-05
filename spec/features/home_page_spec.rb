require 'rails_helper'

RSpec.feature 'the home page', type: :feature do
  before(:each) { visit root_path }

  scenario 'user can access homepage' do
    expect(page.status_code).to eq(200)
  end

  scenario 'user see relevant information' do
    expect(page).to have_content(/Welcome/i)
  end

  scenario 'header is shown' do
    expect(page).to have_content(/Volca Share/i)
  end

  scenario 'footer is shown' do
    expect(page).to have_content(/by Sean Barrett/i)
  end
end
