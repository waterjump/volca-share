# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'shared/_keys_patches.html.haml', type: :view do
  let(:user) { create(:user) }
  let(:patches) { create_list(:keys_patch, 5, user: create(:user)) }

  let(:render_options) do
    {
      partial: 'shared/keys_patches',
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
        partial: 'shared/keys_patches',
        locals: { current_user: user }
      }
    end
  end

  context 'when no patches are present' do
    let(:patches) { [] }

    it 'shows a message' do
      expect(rendered).to have_content('No patches to show')
    end
  end
end
