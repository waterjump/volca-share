# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'keys/patches/edit.html.haml', type: :view do
  let(:user) { create(:user) }
  let(:patch) { user.keys_patches.create(attributes_for(:keys_patch)) }

  context 'when patch is valid' do
    before do
      @patch = VolcaShare::Keys::PatchViewModel.wrap(patch)
      render
    end

    it 'shows "Edit patch" header' do
      expect(rendered).to have_selector('h1', text: "Edit patch")
    end

    it 'renders volca keys interface' do
      expect(rendered).to have_css('.volca.keys')
    end
  end

  context 'when patch has errors' do
    it 'displays errors' do
      @patch = VolcaShare::Keys::PatchViewModel.wrap(patch)
      @patch.model.attack = 'bort'
      @patch.model.validate

      render

      expect(rendered).to have_text('Attack is not a number')
    end
  end
end

