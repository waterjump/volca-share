# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'tags', type: :feature, js: true do
  let(:user) { create(:user) }

  describe 'tag page' do
    it 'shows user patches' do
      patch1 = create(:keys_patch, user_id: user.id, tag_list: 'cool')
      patch2 = create(:keys_patch, tag_list: 'cool')

      visit keys_patch_path(patch2)

      click_link('#cool')
      expect(page).to have_selector(
        'h1', text: '#cool Volca Keys Patches', visible: false
      )
      expect(page).to have_content(patch1.name)
      expect(page).to have_content(patch2.name)

      click_link(patch2.name)
      expect(current_path).to eq(keys_patch_path(patch2.id))
    end

    it 'shows anonymous patches' do
      patch1 = create(:keys_patch, user_id: nil, tag_list: 'cool')

      visit keys_tags_show_path(tag: :cool)
      expect(page).to have_content(patch1.name)
    end

    it 'has audio preview functionality' do
      create(:user_keys_patch, user_id: user.id, tag_list: 'cool')

      visit keys_tags_show_path(tag: :cool)
      page.find('.speaker').click

      expect(page).to have_selector('#preview-modal-body')
    end

    context 'when a tag has no patches' do
      it 'indicates there are no patches to show' do
        visit keys_tags_show_path(tag: :fake)
        expect(page).to have_content('No patches to show.')
      end
    end
  end
end
