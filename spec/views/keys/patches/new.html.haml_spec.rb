# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'keys/patches/new.html.haml', type: :view do
  xit 'shows initialized values' do
    @patch = VolcaShare::Keys::PatchViewModel.wrap(Keys::Patch.new)
    render
    expect(rendered).to have_css('#vco_group_three_light.lit')
    expect(rendered).to have_css('#lfo_target_cutoff_light.lit')
    expect(rendered).to have_css('#vco3_wave_light.lit')
  end
end
