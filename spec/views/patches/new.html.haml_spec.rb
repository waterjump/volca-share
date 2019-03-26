# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'patches/new.html.haml', type: :view do
  it 'shows initialized values' do
    @patch = VolcaShare::PatchViewModel.wrap(Patch.new)
    render
    expect(rendered).to have_css('#vco_group_three_light.lit')
    expect(rendered).to have_css('#lfo_target_cutoff_light.lit')
    expect(rendered).to have_css('#vco3_wave_light.lit')
  end
end
