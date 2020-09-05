# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'shared/_patches.html.haml', type: :view do
  let(:user) { create(:user) }
  let(:sort) { :quality }
  let(:show_audio_filter) { false }
  let(:params) { {} }

  let(:render_options) do
    {
      partial: 'shared/patches.html.haml',
      locals: { current_user: nil, params: params }
    }
  end

  before do
    @sort = sort
    @show_audio_filter = show_audio_filter
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

  context 'when audio only filter is on' do
    let(:show_audio_filter) { true }
    let(:patches) { [create(:patch)] }
    let(:params) { { audio_only: 'true' } }

    describe 'date created sort' do
      it 'keeps audio_only parameter' do
        expect(rendered).to(
          have_css('a[href="/patches?audio_only=true&sort=newest"]')
        )
      end
    end

    describe 'quality sort' do
      let(:sort) { :created_at }

      it 'keeps audio_only parameter' do
        expect(rendered).to(
          have_css('a[href="/patches?audio_only=true"]')
        )
      end
    end
  end

  context 'when audio only filter is off' do
    let(:patches) { [create(:patch)] }

    describe 'date created sort' do
      it 'does not have audio_only parameter' do
        expect(rendered).to(
          have_css('a[href="/patches?sort=newest"]')
        )
      end
    end

    describe 'quality sort' do
      let(:sort) { :created_at }

      it 'does not have audio_only parameter' do
        expect(rendered).to(
          have_css('a[href="/patches"]')
        )
      end
    end
  end
end
