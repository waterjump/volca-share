require 'rails_helper'

RSpec.describe 'User profile page', type: :feature, js: true do
  let(:user) { FactoryGirl.create(:user, username: 'arly.lowe') }

  before(:each) { visit root_path }

  it 'shows patch previews in iframe' do
    FactoryGirl.create(:patch, user_id: user.id, secret: false)
    visit user_path(user.slug)
    first('.speaker').click
    expect(page).to have_selector('#audio-preview-modal')
  end

  it 'shows user created patches' do
    patch1 = FactoryGirl.create(:patch, user_id: user.id, secret: false)
    patch2 = FactoryGirl.create(:patch, user_id: user.id, secret: true)

    visit user_path(user.slug)
    expect(page).to have_selector 'h1', text: "Patches by #{user.username}"
    expect(page).to have_title("Patches by #{user.username} | VolcaShare")
    expect(page).to have_content(patch1.name)
    expect(page).not_to have_content(patch2.name)

    visit root_path
    click_link user.username
    expect(page).to have_title("Patches by #{user.username} | VolcaShare")
    expect(page).to have_content(patch1.name)
    expect(page).not_to have_content(patch2.name)

    visit patch_path(patch1.slug)
    click_link user.username
    expect(page).to have_title("Patches by #{user.username} | VolcaShare")
    expect(page).to have_content(patch1.name)
    expect(page).not_to have_content(patch2.name)
  end

  scenario 'logged in user can see their secret patches' do
    patch1 = FactoryGirl.create(:patch, secret: false, user_id: user.id)
    patch2 = FactoryGirl.create(:patch, secret: true, user_id: user.id)

    login

    visit user_path(user.slug)
    expect(page).to have_content(patch1.name)
    expect(page).to have_content(patch2.name)
  end
end
