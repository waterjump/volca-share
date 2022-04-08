# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'tags', type: :feature, js: true do
  let(:user) { FactoryBot.create(:user) }

  describe 'tag page' do
    # TODO: Decide how to test navigating to certain feature areas.  For
    #   example, patch index page links to tag pages, as do patch detail pages,
    #   and tags page does the same in reverse.  Which one is best to test,
    #   because testing bidirectionally would be redundant.
    xit 'can be navigated to from patch detail page'
    xit 'can be navigated to from patch index page'

    it 'shows user patches' do
      patch1 = FactoryBot.create(:patch, user_id: user.id, tag_list: 'cool')
      patch2 = FactoryBot.create(:patch, tag_list: 'cool')

      visit patch_path(patch2)

      click_link('#cool')
      expect(page).to have_selector 'h1', text: '#cool tags', visible: false
      expect(page).to have_content(patch1.name)
      expect(page).to have_content(patch2.name)

      click_link(patch2.name)
      expect(current_path).to eq(patch_path(patch2.id))
    end

    it 'shows anonymous patches' do
      patch1 = FactoryBot.create(:patch, user_id: nil, tag_list: 'cool')

      visit tags_show_path(tag: :cool)
      expect(page).to have_content(patch1.name)
    end

    it 'does not have audio_only filter' do
      create(:patch, user_id: nil, tag_list: 'cool')

      visit tags_show_path(tag: :cool)
      expect(page).not_to have_css('#audio_only')
    end

    it 'has audio preview functionality' do
      create(:user_patch, user: user, tag_list: 'cool')

      visit tags_show_path(tag: :cool)
      page.find('.speaker', match: :first).click

      expect(page).to have_selector('#preview-modal-body')
    end

    context 'when a tag has no patches' do
      it 'indicates there are no patches to show' do
        visit tags_show_path(tag: :fake)
        expect(page).to have_content('No patches to show.')
      end
    end
  end
end
