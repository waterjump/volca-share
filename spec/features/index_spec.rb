# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Patch index page', type: :feature, js: true do
  let(:user) { FactoryBot.create(:user) }

  it 'can be accessed by link in header' do
    visit root_path
    click_link('Bass')
    first(:link, 'Patches').click
    expect(current_path).to eq(patches_path)
  end

  it 'is sorted by quality' do
    okay_patch = create(:patch, name: 'okay', audio_sample: '')
    complete_patch = create(:user_patch, name: 'complete')
    minimal_patch = create(
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

  context 'when two patches have the same quality but different age' do
    it 'shows newer patch of same quality first' do
      older_equal_patch = create(:user_patch, created_at: 2.days.ago)
      new_equal_patch = create(:user_patch, created_at: 1.day.ago)
      newest_low_qual_patch = create(:patch)

      visit patches_path

      expect(older_equal_patch.quality).to eq(new_equal_patch.quality)

      expect(all('.patch')[0]).to have_link(new_equal_patch.name)
      expect(all('.patch')[1]).to have_link(older_equal_patch.name)
      expect(all('.patch')[2]).to have_link(newest_low_qual_patch.name)
    end
  end

  it 'can be sorted to show newest' do
    okay_patch = create(:patch, name: 'okay', audio_sample: '')
    complete_patch = create(:user_patch, name: 'complete')
    minimal_patch = create(
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

  context 'when filtering by audio sample', js: true do
    it 'can filter by patches with audio samples only' do
      patch_with_audio_sample = create(:user_patch)
      patch_without_audio_sample = create(:patch)

      visit patches_path

      find('#audio_only').click

      expect(page).to have_content(patch_with_audio_sample.name)
      expect(page).not_to have_content(patch_without_audio_sample.name)
      expect(page).to have_css('#audio_only[checked=checked]')
    end

    it 'can be unchecked to show patches without audio samples' do
      patch_with_audio_sample = create(:user_patch)
      patch_without_audio_sample = create(:patch)

      visit patches_path(audio_only: true)

      # NOTE: Could remove since these expectations are covered in last test
      expect(page).to have_content(patch_with_audio_sample.name)
      expect(page).not_to have_content(patch_without_audio_sample.name)
      expect(page).to have_css('#audio_only[checked=checked]')

      find('#audio_only').click

      expect(page).to have_content(patch_with_audio_sample.name)
      expect(page).to have_content(patch_without_audio_sample.name)
      expect(page).not_to have_css('#audio_only[checked=checked]')
    end

    context 'when on page 2' do
      let!(:patch_with_audio_sample) { create(:user_patch) }
      before do
        create_list(:patch, 22)
      end

      it 'resets pagination' do
        visit patches_path

        within first('.pagination') do
          click_link '2'
        end

        find('#audio_only').click

        expect(page).to have_content(patch_with_audio_sample.name)
      end
    end

    context 'when paginating audio only patches' do
      let(:oldest_patch_with_audio) do
        create(:user_patch, created_at: 1.day.ago)
      end

      before do
        oldest_patch_with_audio
        create_list(:user_patch, 22)
      end

      it 'shows oldest audio only user patch on second page' do
        visit patches_path

        click_link 'Date Created'

        find('#audio_only').click

        within first('.pagination') do
          click_link '2'
        end

        expect(page).to have_content(oldest_patch_with_audio.name)
      end
    end
  end

  context 'when user is logged in' do
    it 'allows user to delete their own patches', js: true do
      FactoryBot.create(:patch, user_id: user.id)

      login
      visit patches_path

      accept_confirm { click_button('Delete') }

      expect(page).to have_content('No patches to show.')
    end

    it 'links to the edit patch page', :js do
      patch = FactoryBot.create(:patch, user_id: user.id)

      login
      visit patches_path

      page.find(:css, '.edit').click

      expect(page).to have_content('Edit patch')
    end
  end

  context 'when user is not logged in' do
    it 'shows anonymous patches' do
      patch = create(:patch)

      visit patches_path

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

  describe 'pagination' do
    let(:first_patch) do
      create(
        :user_patch,
        user_id: user.id,
        notes: '',
        audio_sample: '',
        tags: []
      )
    end

    let(:last_patch) { create(:user_patch, user_id: user.id) }

    before do
      first_patch
      20.times { create(:user_patch, user: user, audio_sample: '') }
      last_patch

      visit patches_path
    end

    describe 'control' do
      it 'is shown at the top and bottom of the page' do
        expect(page).to have_css('.pagination', count: 2)
      end
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
      before { first('.pagination').click_link('2') }

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

  context 'when a patch has tags' do
    it 'shows link to tag page' do
      create(:patch, user_id: user.id, tag_list: 'cool')

      visit patches_path
      click_link('#cool')

      expect(page).to have_content('#cool tags')
    end
  end

  context 'when audio sample is available' do
    describe 'audio previews are shown', :js do
      let!(:patch) { create(:user_patch, user: user) }

      before do
        visit patches_path
      end

      describe 'audio preview' do
        before { first('.speaker').click }

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

  context 'when audio sample is unavailable' do
    let!(:patch) do
      create(:patch, user_id: user.id).tap do |patch|
        patch.audio_sample_available = false
        patch.save(validate: false)
      end
    end

    it 'does not show audio preview' do
      visit patches_path

      expect(page).not_to have_selector('.speaker')
    end
  end
end
