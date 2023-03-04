# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'shared/_patch_card.html.haml', type: :view do
  let(:user) { nil }
  let(:patch) { create(:patch, user: create(:user)) }
  let(:patch_view_model) { VolcaShare::PatchViewModel.wrap(patch) }

  let(:render_options) do
    {
      partial: 'shared/patch_card',
      locals: { current_user: user, patch: patch_view_model }
    }
  end

  before { render render_options }

  context 'when user is logged in' do
    let(:user) { create(:user) }

    describe 'patch made by the user' do
      let(:patch) { create(:patch, user: user) }

      it 'shows the edit icon' do
        expect(rendered).to have_css('.edit.glyph')
      end

      it 'shows the delete icon' do
        expect(rendered).to have_css('.delete.glyph')
      end

      it 'links to the user patch path twice' do
        expect(rendered).to(
          have_selector(
            :css, "a[href='#{user_patch_path(user.slug, patch.slug)}']"
          )
        )
      end

      it 'does not link to the anonymous patch path' do
        expect(rendered).not_to(
          have_selector(:css, "a[href='#{patch_path(patch)}']")
        )
      end

      context 'when patch is secret' do
        let(:patch) do
          user.patches.create(attributes_for(:patch, secret: true))
        end

        it 'shows lock icon' do
          expect(rendered).to have_css('.lock.glyph')
        end
      end

      describe 'patch made by someone else' do
        let(:patch) { create(:patch) }

        it 'does not show edit icon' do
          expect(rendered).not_to have_css('.edit.glyph')
        end

        it 'does not show delete icon' do
          expect(rendered).not_to have_css('.delete.glyph')
        end
      end
    end
  end

  context 'when user is not logged in' do
    it 'does not show the edit icon' do
      expect(rendered).not_to have_css('.edit.glyph')
    end

    it 'does not show the delete icon' do
      expect(rendered).not_to have_css('.delete.glyph')
    end
  end

  it 'links to the user profile page of patch author' do
    expect(rendered).to(
      have_link(patch.user.username, href: user_path(patch.user.slug))
    )
  end

  it 'links to the user patch show page by name' do
    expect(rendered).to(
      have_link(
        patch.name,
        href: user_patch_path(patch.user.slug,patch.slug)
      )
    )
  end

  it 'shows the patch notes' do
    expect(rendered).to(
      have_content(
        VolcaShare::PatchViewModel.wrap(patch).notes
      )
    )
  end

  it 'shows date the patch was created' do
    expect(rendered).to(
      have_content(patch.created_at.strftime("%B %-d, %Y"))
    )
  end
end
