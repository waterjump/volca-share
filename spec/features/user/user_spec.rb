require 'rails_helper'

RSpec.feature 'user', type: :feature, js: true do

  let(:user) { FactoryGirl.create(:user) }

  before(:each) { visit root_path }

  scenario 'users created patches are shown on profile page' do
    patch1 = FactoryGirl.create(:patch, user_id: user.id, secret: false)
    patch2 = FactoryGirl.create(:patch, user_id: user.id, secret: true)

    visit user_path(user.slug)
    expect(page).to have_title("Patches by #{user.username} | VolcaShare")
    expect(page).to have_content(patch1.name)
    expect(page).not_to have_content(patch2.name)
  end

  scenario 'logged in user can see their secret patches' do
    patch1 = FactoryGirl.create(:patch, secret: false, user_id: user.id)
    patch2 = FactoryGirl.create(:patch, secret: true, user_id: user.id)

    click_link 'Log in'
    fill_in 'user[email]', with: user.email
    fill_in 'user[password]', with: user.password
    click_button 'Log in'

    visit user_path(user.slug)

    expect(page).to have_content(patch1.name)
    expect(page).to have_content(patch2.name)
  end
end
