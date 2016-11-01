require 'rails_helper'

RSpec.feature 'patches', type: :feature do
  before(:each) { visit root_path }

  scenario 'can be created by users' do
    user = FactoryGirl.create(:user)

    click_link 'Log in'
    fill_in 'user[email]', with: user.email
    fill_in 'user[password]', with: user.password
    click_button 'Log in'

    visit root_path

    click_link 'Patches'
    expect(page).to have_link 'Submit a patch'

    click_link 'Submit a patch'
    expect(current_path).to eq(new_patch_path)
    expect(page.status_code).to eq(200)
  end

  scenario 'cannot be created by guests' do
    click_link 'Patches'
    click_link 'Submit a patch'
    expect(current_path).to eq(new_user_session_path)
    expect(page.status_code).to eq(200)
  end

  scenario 'header is shown' do
    expect(page).to have_content(/VolcaShare/i)
  end

  scenario 'footer is shown' do
    expect(page).to have_content(/Sean Barrett/i)
  end
end
