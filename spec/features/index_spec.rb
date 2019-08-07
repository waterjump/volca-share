# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Patch index page', type: :feature, js: true do

  let(:user) { FactoryBot.create(:user) }

  it 'can be accessed by link in header' do
    visit root_path
    click_link('Browse')
    expect(current_path).to eq(patches_path)
  end

  it 'is sorted by quality' do
    okay_patch = FactoryBot.create(:patch, name: 'okay', audio_sample: '')
    complete_patch = FactoryBot.create(:patch, name: 'complete')
    minimal_patch = FactoryBot.create(
      :patch,
      tags: [],
      notes: '',
      audio_sample: '',
      name: 'minimal'
    )
    visit patches_path
    expect(all('.patch')[0]).to have_link('complete')
    expect(all('.patch')[1]).to have_link('okay')
    expect(all('.patch')[2]).to have_link('minimal')
  end

  it 'can be sorted to show newest' do
    okay_patch = FactoryBot.create(:patch, name: 'okay', audio_sample: '')
    complete_patch = FactoryBot.create(:patch, name: 'complete')
    minimal_patch = FactoryBot.create(
      :patch,
      tags: [],
      notes: '',
      audio_sample: '',
      name: 'minimal'
    )
    visit patches_path
    click_link 'Date Created'
    expect(all('.patch')[0]).to have_link('minimal')
    expect(all('.patch')[1]).to have_link('complete')
    expect(all('.patch')[2]).to have_link('okay')
  end

  context 'when user is logged in' do
    it 'allows user to delete their own patches', js: true do
      FactoryBot.create(:patch, user_id: user.id)

      login
      visit patches_path

      accept_confirm { click_button('Delete') }

      expect(page).to have_content('No patches to show.')
    end

    it 'does not allow user to delete patches of others' do
      FactoryBot.create(:patch, user_id: user.id)
      user_2 = FactoryBot.create(:user)

      login(user_2)
      visit patches_path

      expect(page).not_to have_button('Delete')
    end
  end


  context 'when user as not logged in' do
    let!(:patch) { FactoryBot.create(:patch) }

    before { visit patches_path }

    it "doesn't display controls to delete anononymous patches" do
      expect(page).not_to have_button('Delete')
    end

    it "doesn't display controls to edit anononymous patches" do
      expect(page).not_to have_selector('.edit.glyph')
    end

    it 'shows anonymous patches' do
      expect(page).to have_content(patch.name)
    end

    it 'does not show secret patches' do
      patch1 = FactoryBot.create(:patch, user_id: user.id)
      patch2 = FactoryBot.create(:patch, secret: true, user_id: user.id)

      visit patches_path

      expect(page).to have_content(patch1.name)
      expect(page).not_to have_content(patch2.name)
    end
  end

  describe 'pagination of patch index' do
    let(:first_patch) do
      FactoryBot.create(
        :patch,
        user_id: user.id,
        notes: '',
        audio_sample: '',
        tags: []
      )
    end
    let(:last_patch) do
      FactoryBot.create(:patch, user_id: user.id)
    end

    before do
      first_patch
      20.times { FactoryBot.create(:patch, user_id: user.id, audio_sample: '') }
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

      it 'doesn\'t show newest 20 patches' do
        expect(page).not_to have_content(last_patch.name)
      end

      it 'shows oldest patch' do
        expect(page).to have_content(first_patch.name)
      end

      it 'show the pagination controls' do
        expect(page).to have_selector('.pagination')
      end

      it 'shows remaining patches' do
        expect(page).to have_selector('.patch-holder', count: 2)
      end

      it 'shows pagination links to other pages' do
        expect(page).to have_link('1')
      end
    end
  end

  context 'when a patch has tags' do
    it 'shows link to tag page' do
      patch1 = FactoryBot.create(:patch, user_id: user.id,tag_list: 'cool')

      visit patch_path(patch1)
      click_link('#cool')

      expect(page).to have_current_path(tags_show_path(tag: 'cool'))
    end
  end

  describe 'audio previews are shown' do
    let(:patch) do
      FactoryBot.create(:patch, user_id: user.id)
    end

    before do
      patch
      visit patches_path
    end

    it 'shows the speaker icon' do
      expect(first('.patch')).to have_css('.speaker')
    end

    describe 'audio preview' do
      before do
        first('.speaker').click
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
