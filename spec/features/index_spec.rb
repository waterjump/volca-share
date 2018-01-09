require 'rails_helper'

RSpec.describe 'Patch index page', type: :feature, js: true do

  let(:user) { FactoryBot.create(:user) }

  before(:each) { visit root_path }

  scenario 'can be deleted by author on patch browse page' do
    FactoryBot.create(:patch, secret: false, user_id: user.id)

    login
    visit patches_path
    click_button('Delete')
    visit patches_path

    expect(page).to have_content('No patches to show.')
  end

  scenario 'cannot be deleted by non-author on patch browse page' do
    FactoryBot.create(:patch, secret: false, user_id: user.id)
    user_2 = FactoryBot.create(:user)

    login(user_2)
    visit patches_path

    expect(page).not_to have_button('Delete')
  end

  scenario 'that are private are not shown on the index' do
    patch1 = FactoryBot.create(:patch, secret: false, user_id: user.id)
    patch2 = FactoryBot.create(:patch, secret: true, user_id: user.id)

    visit root_path

    expect(page).to have_content(patch1.name)
    expect(page).not_to have_content(patch2.name)
  end

  describe 'as anonymous user' do
    let(:patch) { FactoryBot.create(:patch, secret: false) }

    before do
      patch
      visit root_path
    end

    it 'doesn\'t display controls to delete anononymous patches' do
      expect(page).not_to have_button('Delete')
    end

    it 'doesn\'t display controls to edit anononymous patches' do
      expect(page).not_to have_selector('.edit.glyph')
    end

    it 'shows anonymous patches' do
      expect(page).to have_content(patch.name)
    end
  end

  describe 'pagination of patch index' do
    let(:first_patch) do
      FactoryBot.create(:patch, secret: false, user_id: user.id)
    end
    let(:last_patch) do
      FactoryBot.create(:patch, secret: false, user_id: user.id)
    end

    before do
      first_patch
      30.times do
        FactoryBot.create(:patch, secret: false, user_id: user.id)
      end
      last_patch
      visit patches_path
    end

    describe 'first page' do
      it 'shows most recent patches first' do
        expect(page).to have_content(last_patch.name)
      end

      it 'does not show patches older than newest 20' do
        expect(page).not_to have_content(first_patch.name)
      end

      it 'shows the pagination controls' do
        expect(page).to have_selector('.pagination')
      end

      it 'shows 20 patches per page' do
        expect(page).to have_selector('.patch-holder', count: 20)
      end

      it 'shows link to next page' do
        within '.pagination' do
          expect(page).to have_link('2')
        end
      end

      it 'doesn\'t show link to invalid pages' do
        within '.pagination' do
          expect(page).not_to have_link('3')
        end
      end
    end

    describe 'second page' do
      before { click_link '2' }

      it 'doesn\'t show newewst 20 patches' do
        expect(page).not_to have_content(last_patch.name)
      end

      it 'shows oldest patch' do
        expect(page).to have_content(first_patch.name)
      end

      it 'show the pagination controls' do
        expect(page).to have_selector('.pagination')
      end

      it 'shows remaining patches' do
        expect(page).to have_selector('.patch-holder', count: 12)
      end

      it 'shows pagination links to other pages' do
        expect(page).to have_link('1')
      end
    end
  end

  scenario 'link to tag pages are shown' do
    patch1 = FactoryBot.create(
      :patch,
      secret: false,
      user_id: user.id,
      tag_list: 'cool'
    )

    visit patch_path(patch1)
    click_link('#cool')
    expect(page).to have_current_path(tags_show_path(tag: 'cool'))
  end

  describe 'audio previews are shown' do
    let(:patch) do
      FactoryBot.create(:patch, user_id: user.id, secret: false)
    end

    before do
      patch
      visit patches_path
    end

    it 'shows the speaker icon' do
      within '.patch-holder' do
        expect(page).to have_xpath('/html/body/div[1]/div[2]/div[3]/div[2]/div[1]')
      end
    end

    describe 'audio preview' do
      before do
        within '.patch-holder' do
          find(:xpath, '/html/body/div[1]/div[2]/div[3]/div[2]/div[1]').click
        end
      end

      it 'shows preview in an iframe' do
        expect(page).to have_selector('iframe')
      end

      it 'links to patch' do
        click_link 'Go to Patch'
        expect(page.current_path).to eq(user_patch_path(user.slug, patch.slug))
      end
    end
  end
end
