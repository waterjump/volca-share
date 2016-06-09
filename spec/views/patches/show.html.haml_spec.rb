require 'rails_helper'

RSpec.describe 'patches/show', type: :view do
  before(:each) do
    @patch = assign(:patch, Patch.create!(
                              name: 'Name',
                              tempo: 1,
                              attack: 2,
                              decay_release: 3,
                              cutoff_eg_int: 4,
                              peak: 5,
                              cutoff: 6,
                              lfo_rate: 7,
                              lfo_int: 8,
                              vco1_pitch: 9,
                              vco1_active: false,
                              vco2_pitch: 10,
                              vco2_active: false,
                              vco3_pitch: 11,
                              vco3_active: false,
                              vco_group: 'Vco Group',
                              lfo_target_amp: false,
                              lfo_target_pitch: false,
                              lfo_target_cutoff: false,
                              lfo_wave: 'Lfo Wave',
                              vco1_wave: 'Vco1 Wave',
                              vco2_wave: 'Vco2 Wave',
                              vco3_wave: 'Vco3 Wave',
                              sustain_on: false,
                              amp_eg_on: false,
                              tags: '',
                              type: 'Type'
    ))
  end

  it 'renders attributes in <p>' do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/1/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/4/)
    expect(rendered).to match(/5/)
    expect(rendered).to match(/6/)
    expect(rendered).to match(/7/)
    expect(rendered).to match(/8/)
    expect(rendered).to match(/9/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/10/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/11/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/Vco Group/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/Lfo Wave/)
    expect(rendered).to match(/Vco1 Wave/)
    expect(rendered).to match(/Vco2 Wave/)
    expect(rendered).to match(/Vco3 Wave/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(//)
    expect(rendered).to match(/Type/)
  end
end
