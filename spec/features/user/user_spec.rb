# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User profile page', type: :feature, js: true do
  let(:user) { FactoryBot.create(:user, username: 'arly.lowe') }

  context 'when user is logged in' do
    before { login }
    it 'can be accessed via the top navigation' do
      click_link 'My Patches'

      expect(current_path).to eq(user_path(user.slug))
    end

    context 'and secret patches are present' do
      it 'displays secret patches' do
        patch1 = FactoryBot.create(:patch, user_id: user.id)
        patch2 = FactoryBot.create(:patch, secret: true, user_id: user.id)

        visit user_path(user.slug)

        expect(page).to have_content(patch1.name)
        expect(page).to have_content(patch2.name)
      end
    end
  end

  it 'shows patch previews in iframe' do
    FactoryBot.create(:patch, user_id: user.id)
    visit user_path(user.slug)
    first('.speaker').click
    expect(page).to have_selector('#audio-preview-modal')
  end

  it 'shows user created patches' do
    patch1 = FactoryBot.create(:patch, user_id: user.id)
    patch2 = FactoryBot.create(:patch, user_id: user.id, secret: true)

    visit user_path(user.slug)
    expect(page).to have_selector 'h1', text: "Patches by #{user.username}"
    expect(page).to have_title("Patches by #{user.username} | VolcaShare")
    expect(page).to have_content(patch1.name)
    expect(page).not_to have_content(patch2.name)

    visit patches_path
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
end
