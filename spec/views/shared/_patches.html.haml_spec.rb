# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'shared/_patches.html.haml', type: :view do
  let(:user) { create(:user) }

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

  context 'when no patches are present' do
    let(:patches) { [] }

    it 'shows a message' do
      expect(rendered).to have_content('No patches to show')
    end
  end
end
