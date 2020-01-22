# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'keys/patches/_form.html.haml', type: :view do
  xcontext 'when patch has an audio sample' do
    let!(:user) { FactoryBot.build(:user) }
    let(:user_patch) do
      VolcaShare::PatchViewModel.wrap(
        user.patches.build(FactoryBot.attributes_for(:patch))
      )
    end
    it 'shows a preview of the audio sample' do
      @patch = user_patch
      render partial: 'keys/patches/form.html.haml', locals: { current_user: user }
      expect(rendered).to have_css('.sample')
    end
  end

  xit 'shows tag input placeholders' do
    @patch = VolcaShare::PatchViewModel.wrap(Patch.new)
    render partial: 'keys/patches/form.html.haml'
    expect(rendered).to have_selector(
      'input[placeholder="tags, separated, by, commas"]'
    )
  end
end
