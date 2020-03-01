# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'shared/_keys_patches.html.haml', type: :view do
  let(:user) { create(:user) }
  let(:patches) { create_list(:keys_patch, 5) }

  let(:render_options) do
    {
      partial: 'shared/keys_patches.html.haml',
      locals: { current_user: nil }
    }
  end

  before do
    @keys_patches = Kaminari.paginate_array(
      VolcaShare::Keys::PatchViewModel.wrap(patches)
    ).page(1)

    render render_options
  end

  context 'when user is logged in' do
    let(:render_options) do
      {
        partial: 'shared/keys_patches.html.haml',
        locals: { current_user: user }
      }
    end

    describe 'patches made by the user' do
      let(:patches) { create_list(:keys_patch, 5, user: user) }

      it 'shows the edit icon' do
        expect(rendered).to have_css('.edit.glyph')
      end

      it 'shows the delete icon' do
        expect(rendered).to have_css('.delete.glyph')
      end

      context 'when patch is secret' do
        let(:patches) do
          [user.keys_patches.create(attributes_for(:keys_patch, secret: true))]
        end

        it 'shows lock icon' do
          expect(rendered).to have_css('.lock.glyph')
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

  it 'links to the patch show page by name' do
    expect(rendered).to(
      have_link(patches.first.name, href: keys_patch_path(patches.first))
    )
  end

  it 'shows the patch description' do
    expect(rendered).to(
      have_content(
        VolcaShare::Keys::PatchViewModel.wrap(patches.first).description
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
