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
    expect(rendered).to have_css('#lfo_shape_saw_light')
    expect(rendered).to have_css('#lfo_shape_triangle_light.lit')
    expect(rendered).to have_css('#lfo_shape_square_light')
    expect(rendered).to have_css('#lfo_trigger_sync_light')
    expect(rendered).to have_css('#step_trigger_light')
    expect(rendered).to have_css('#tempo_delay_light')
  end

  xit 'shows tag input placeholders' do
    @patch = VolcaShare::PatchViewModel.wrap(Patch.new)
    render partial: 'keys/patches/form.html.haml'
    expect(rendered).to have_selector(
      'input[placeholder="tags, separated, by, commas"]'
    )
  end
end
