require 'rails_helper'

RSpec.feature 'patches', type: :feature do
  before(:each) { visit root_path }

  scenario 'can be created by users' do
    create_user_and_login
    expect(page.status_code).to eq(200)
  end

  scenario 'cannot be created by guests' do
    expect(page).to have_content(/Hello/i)
  end

  scenario 'header is shown' do
    expect(page).to have_content(/VolcaShare/i)
  end

  scenario 'footer is shown' do
    expect(page).to have_content(/Sean Barrett/i)
  end
end
