# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Keys patch index page', type: :feature do
  let(:user) { create(:user) }

  it 'can be accessed by link in header' do
    visit root_path
    click_link('Keys')
    within '.dropdown-menu.keys' do
      page.find(:link, 'Browse').click
    end
    expect(current_path).to eq(keys_patches_path)
  end

  it 'is sorted by quality' do
    okay_patch = create(:keys_patch, name: 'okay', audio_sample: '')
    complete_patch = create(:user_keys_patch, name: 'complete')
    minimal_patch = create(
      :keys_patch,
      tags: [],
      notes: '',
      audio_sample: '',
      name: 'minimal'
    )

    visit keys_patches_path

    expect(all('.patch')[0]).to have_link('complete')
    expect(all('.patch')[1]).to have_link('okay')
    expect(all('.patch')[2]).to have_link('minimal')
  end

  it 'can be sorted to show newest' do
    okay_patch = create(:keys_patch, name: 'okay', audio_sample: '')
    complete_patch = create(:keys_patch, name: 'complete')
    minimal_patch = create(
      :keys_patch,
      tags: [],
      notes: '',
      audio_sample: '',
      name: 'minimal'
    )

    visit keys_patches_path

    click_link 'Date Created'

    expect(all('.patch')[0]).to have_link('minimal')
    expect(all('.patch')[1]).to have_link('complete')
    expect(all('.patch')[2]).to have_link('okay')
  end

  context 'when user is logged in' do
    it 'allows user to delete their own patches', js: true do
      create(:keys_patch, user_id: user.id)

      login
      visit keys_patches_path

      accept_confirm { click_button('Delete') }

      expect(page).to have_content('No patches to show.')
    end

    it 'links to the edit patch page', :js do
      patch = create(:keys_patch, user_id: user.id)

      login
      visit keys_patches_path

      page.find(:css, '.edit').click

      expect(page).to have_content('Edit patch')
    end
  end

  context 'when user is not logged in' do
    it 'shows anonymous patches' do
      patch = create(:keys_patch)

      visit keys_patches_path

      expect(page).to have_content(patch.name)
    end

    it 'does not show secret patches' do
      patch1 = create(:keys_patch, user_id: user.id)
      patch2 = create(:keys_patch, secret: true, user_id: user.id)

      visit keys_patches_path

      expect(page).to have_content(patch1.name)
      expect(page).not_to have_content(patch2.name)
    end
  end

  describe 'pagination' do
    let(:first_patch) do
      create(
        :keys_patch,
        user_id: user.id,
        notes: '',
        audio_sample: '',
        tags: []
      )
    end

    let(:last_patch) { create(:user_keys_patch, user_id: user.id) }

    before do
      first_patch
      20.times { create(:keys_patch, user_id: user.id, audio_sample: '') }
      last_patch

      visit keys_patches_path
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
        expect(page).to have_link('1')
      end

      it 'shows remaining patches' do
        expect(page).to have_selector('.patch-holder', count: 2)
      end
    end
  end

  context 'when audio sample is available' do
    describe 'audio previews are shown', :js do
      let!(:patch) { create(:user_keys_patch, user: user) }

      before do
        visit keys_patches_path
      end

      describe 'audio preview' do
        before { first('.speaker').click }

        it 'shows preview in an iframe' do
          expect(page).to have_selector('iframe')
        end

        it 'links to patch' do
          click_link 'Go to Patch'

          expect(page.current_path).to(
            eq(user_keys_patch_path(user.slug, patch.slug))
          )
        end
      end
    end
  end

  context 'when audio sample is unavailable' do
    let!(:patch) do
      create(:keys_patch, user_id: user.id).tap do |patch|
        patch.audio_sample_available = false
        patch.save(validate: false)
      end
    end

    it 'does not show audio preview' do
      visit keys_patches_path

      expect(page).not_to have_selector('.speaker')
    end
  end
end
