# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'shared/_patches.html.haml', type: :view do
  let(:user) { create(:user) }
  let(:patches) { create_list(:patch, 5) }

  let(:render_options) do
    {
      partial: 'shared/patches.html.haml',
      locals: { current_user: nil }
    }
  end

  before do
    @patches = Kaminari.paginate_array(
      VolcaShare::PatchViewModel.wrap(patches)
    ).page(1)

    render render_options
  end

  context 'when patch is a user patch' do
    let(:patches) { create_list(:patch, 1, user: user) }

    it 'links to the user patch path twice' do
      expect(rendered).not_to(
        have_selector(:css, "a[href='#{patch_path(patches.first)}']")
      )
    end
  end

  context 'when user is logged in' do
    let(:render_options) do
      {
        partial: 'shared/patches.html.haml',
        locals: { current_user: user }
      }
    end

    describe 'patches made by the user' do
      let(:patches) { create_list(:patch, 5, user: user) }

      it 'shows the edit icon' do
        expect(rendered).to have_css('.edit.glyph')
      end

      it 'shows the delete icon' do
        expect(rendered).to have_css('.delete.glyph')
      end

      context 'when patch is secret' do
        let(:patches) do
          [user.patches.create(attributes_for(:patch, secret: true))]
        end

        it 'shows lock icon' do
          expect(rendered).to have_css('.lock.glyph')
        end
      end
    end

    describe 'patch made by someone else' do
      let(:patches) { [create(:patch)] }

      it 'does not show edit icon' do
        expect(rendered).not_to have_css('.edit.glyph')
      end

      it 'does not show delete icon' do
        expect(rendered).not_to have_css('.delete.glyph')
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

  it 'shows the patch description' do
    expect(rendered).to(
      have_content(
        VolcaShare::PatchViewModel.wrap(patches.first).description
      )
    )
  end

  it 'shows date the patch was created' do
    expect(rendered).to(
      have_content(
        patches.first.created_at.strftime(
          "%B #{patches.first.created_at.day.ordinalize}, %Y"
        )
      )
    )
  end

  context 'when no patches are present' do
    let(:patches) { [] }

    it 'shows a message' do
      expect(rendered).to have_content('No patches to show')
    end
  end
end
