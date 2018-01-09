require 'rails_helper'

RSpec.describe 'patches/show.html.haml', type: :view do
  let!(:user) { FactoryBot.build(:user) }
  let(:user_patch) do
    VolcaShare::PatchViewModel.wrap(
      user.patches.build(FactoryBot.attributes_for(:patch))
    )
  end
  let(:anonymous_patch) do
    VolcaShare::PatchViewModel.wrap(
      FactoryBot.build(:patch)
    )
  end
  context 'baseline functionality' do
    before do
      @patch = user_patch
      render
    end
    it 'reflects the patch' do
      reflects_patch(@patch, interface: rendered)
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
  context 'when user is logged in' do
    before do
      @patch = user_patch
      render
    end
    context 'when user is author' do
      before do
        render template: 'patches/show.html.haml', locals: { current_user: user }
      end

      it 'shows edit link' do
        expect(rendered).to have_link('Edit')
      end
      it 'shows delete link' do
        expect(rendered).to have_button('Delete')
      end
    end
    context 'when user is not author' do
      before do
        render(
          template: 'patches/show.html.haml',
          locals: { current_user: FactoryBot.create(:user) }
        )
      end
      it 'does not show edit link' do
        expect(rendered).not_to have_link('Edit')
      end
      it 'does not show delete link' do
        expect(rendered).not_to have_link('Delete')
      end
    end
  end
  context 'when user is anonymous' do
    before do
      @patch = user_patch
      render(
        template: 'patches/show.html.haml',
        locals: { current_user: FactoryBot.create(:user) }
      )
    end
    it 'does not show edit link' do
      expect(rendered).not_to have_link('Edit')
    end
    it 'does not show delete link' do
      expect(rendered).not_to have_link('Delete')
    end
    it 'reflects the patch' do
      reflects_patch(@patch, interface: rendered)
    end
  end
  context 'when patch author is anonymous' do
    before do
      @patch = anonymous_patch

      render(
        template: 'patches/show.html.haml',
        locals: { current_user: FactoryBot.create(:user) }
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
    it 'does not show delete link' do
      expect(rendered).not_to have_link('Delete')
    end
    it 'shows the volca interface' do
      expect(rendered).to have_css('.volca')
    end
    it 'accurately reflects patch settings' do
      reflects_patch(anonymous_patch, interface: rendered)
    end
    it 'shows the shruggy' do
      expect(rendered).to have_content('by ¯\_(ツ)_/¯')
    end
  end
end
