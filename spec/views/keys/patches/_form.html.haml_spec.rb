# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'keys/patches/_form.html.haml', type: :view do
  context 'when user is logged in' do
    let(:user) { build(:user) }
    let(:locals) { { current_user: user } }
    let(:user_patch) do
      VolcaShare::Keys::PatchViewModel.wrap(create(:user_keys_patch, user: user))
    end

    before do
      @patch = user_patch
      render partial: 'keys/patches/form.html.haml', locals: locals
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

  it 'shows controls from the keys machine' do
    @patch = VolcaShare::Keys::PatchViewModel.wrap(Keys::Patch.new)
    render

    expect(rendered).to have_css('#voice')
    expect(rendered).to have_css('#octave')
    expect(rendered).to have_css('#detune')
    expect(rendered).to have_css('#portamento')
    expect(rendered).to have_css('#vco_eg_int')
    expect(rendered).to have_css('#cutoff')
    expect(rendered).to have_css('#peak')
    expect(rendered).to have_css('#vcf_eg_int')
    expect(rendered).to have_css('#lfo_rate')
    expect(rendered).to have_css('#lfo_pitch_int')
    expect(rendered).to have_css('#lfo_cutoff_int')
    expect(rendered).to have_css('#attack')
    expect(rendered).to have_css('#decay_release')
    expect(rendered).to have_css('#sustain')
    expect(rendered).to have_css('#delay_time')
    expect(rendered).to have_css('#delay_feedback')

    # Bottom row
    expect(rendered).to have_css('#lfo_shape_saw_light.unlit')
    expect(rendered).to have_css('#lfo_shape_triangle_light.lit')
    expect(rendered).to have_css('#lfo_shape_square_light.unlit')
    expect(rendered).to have_css('#lfo_trigger_sync_light.unlit')
    expect(rendered).to have_css('#step_trigger_light.unlit')
    expect(rendered).to have_css('#tempo_delay_light.lit')
  end

  context 'when user is logged in' do
    before do
      @patch = VolcaShare::Keys::PatchViewModel.wrap(Keys::Patch.new)
      render(
        partial: 'keys/patches/form.html.haml',
        locals: { current_user: create(:user) }
      )
    end

    it 'shows checkbox to make the patch secret' do
      expect(rendered).to have_css('#patch_secret')
    end

    it 'has an audio sample field' do
      expect(rendered).to have_css('#patch_audio_sample')
    end
  end

  it 'shows tag input placeholders' do
    @patch = VolcaShare::Keys::PatchViewModel.wrap(Keys::Patch.new)

    render partial: 'keys/patches/form.html.haml'

    expect(rendered).to have_selector(
      'input[placeholder="tags, separated, by, commas"]'
    )
  end
end
