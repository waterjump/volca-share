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

    it 'does not show edit link' do
      expect(rendered).not_to have_link('Edit')
    end
  end

  context 'when user is logged in' do
    before { @patch = user_patch }

    context 'when user is author' do
      before do
        render(
          template: 'keys/patches/show.html.haml',
          locals: { current_user: user }
        )
      end

      it 'shows edit link' do
        expect(rendered).to have_link('Edit')
      end
    end

    context 'when user is not the author' do
      before do
        render(
          template: 'keys/patches/show.html.haml',
          locals: { current_user: create(:user) }
        )
      end

      it 'does not show edit link' do
        expect(rendered).not_to have_link('Edit')
      end
    end
  end

  context 'when patch author is anonymous' do
    before do
      @patch = anonymous_patch

      render(
        template: 'keys/patches/show.html.haml',
        locals: { current_user: nil }
      )
    end

    it 'has h1 for SEO purposes' do
      expect(rendered).to have_selector(
        'h1',
        text: "#{@patch.name} by ¯\\_(ツ)_/¯",
        visible: false
      )
    end

    it 'does not show edit link' do
      expect(rendered).not_to have_link('Edit')
    end

    it 'shows the volca interface' do
      expect(rendered).to have_css('.volca.keys')
    end

    it 'shows the shruggy' do
      expect(rendered).to have_content('by ¯\_(ツ)_/¯')
    end
  end
end

