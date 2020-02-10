# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'keys/patches/show.html.haml', type: :view do
  let!(:user) { FactoryBot.build(:user) }
  let(:user_patch) do
    VolcaShare::Keys::PatchViewModel.wrap(
      user.keys_patches.build(FactoryBot.attributes_for(:keys_patch))
    )
  end
  let(:anonymous_patch) do
    VolcaShare::Keys::PatchViewModel.wrap(FactoryBot.build(:keys_patch))
  end

  context 'baseline functionality' do
    before do
      @patch = user_patch
      render
    end

    it 'reflects the patch' do
      reflects_keys_patch(@patch, interface: rendered)
    end

    it 'includes h1 header' do
      expect(rendered).to have_selector(
        'h1',
        text: "#{@patch.name} by #{user.username}",
        visible: false
      )
    end

    it 'displays author name' do
      expect(rendered).to have_content("by #{@patch.user.username}")
    end
  end
end

