# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'patches/_form.html.haml', type: :view do
  let(:locals) { { } }

  it 'shows tag input placeholders' do
    @patch = VolcaShare::PatchViewModel.wrap(Patch.new)
    render partial: 'patches/form.html.haml'
    expect(rendered).to have_selector(
      'input[placeholder="tags, separated, by, commas"]'
    )
  end

  context 'when user is logged in' do
    let(:user) { build(:user) }
    let(:locals) { { current_user: user } }
    let(:user_patch) do
      VolcaShare::PatchViewModel.wrap(create(:user_patch, user: user))
    end

    before do
      @patch = user_patch
      render partial: 'patches/form.html.haml', locals: locals
    end

    context 'when patch has an audio sample' do
      it 'shows a preview of the audio sample' do
        expect(rendered).to have_css('.sample')
      end
    end

    it 'tells how to rank higher on browse page' do
      expect(rendered).to(
        have_content(
          'Note: Giving your patch tags, a description, and especially an '\
          'audio sample will help it rank higher on browse pages.'
        )
      )
    end
  end

  context 'when user is not logged in' do
    it 'shows a link to create account' do
      @patch = VolcaShare::PatchViewModel.wrap(Patch.new)

      render partial: 'patches/form.html.haml', locals: locals

      expect(rendered).to have_link('create an account')
    end
  end
end
