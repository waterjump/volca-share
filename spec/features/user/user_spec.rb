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

  it 'shows both Bass and Keys patches' do
    keys_patch = user.keys_patches.create(attributes_for(:keys_patch))
    bass_patch = user.patches.create(attributes_for(:patch))

    visit user_path(user.slug)
    expect(page).to have_selector('h3', text: 'Volca Bass Patches')
    expect(page).to have_content(bass_patch.name)
    expect(page).to have_selector('h3', text: 'Volca Keys Patches')
    expect(page).to have_content(keys_patch.name)
  end

  it 'does not have pagination' do
    bass_patches = create_list(:patch, 40, user_id: user.id)
    keys_patches = create_list(:keys_patch, 40, user_id: user.id)

    visit user_path(user.slug)
    expect(page).not_to have_selector('.pagination')
    expect(page).to have_selector('.patch', 80)
  end

  it 'shows user created patches' do
    patch1 = FactoryBot.create(:patch, user_id: user.id)
    patch2 = FactoryBot.create(:patch, user_id: user.id, secret: true)

    visit user_path(user.slug)
    expect(page).to have_selector 'h1', text: "Patches by #{user.username}"
    expect(page).to have_title("Patches by #{user.username} | VolcaShare")
    expect(page).to have_content(patch1.name)
    expect(page).not_to have_content(patch2.name)
  end
end
