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

    describe 'image' do
      it 'links to the user patch path' do
        expect(rendered).not_to(
          have_selector(:css, "a[href='#{patch_path(patches.first)}']")
        )
      end
    end

    it 'links to the user patch path twice' do
      expect(rendered).not_to(
        have_selector(:css, "a[href='#{patch_path(patches.first)}']")
      )
    end
  end
end
