require 'rails_helper'

RSpec.describe 'patches/index', type: :view do
  before(:each) do
    assign(:patches, [
             Patch.create!(
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
             ),
             Patch.create!(
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
             )
           ])
  end

  it 'renders a list of patches' do
    render
    assert_select 'tr>td', text: 'Name'.to_s, count: 2
    assert_select 'tr>td', text: 1.to_s, count: 2
    assert_select 'tr>td', text: 2.to_s, count: 2
    assert_select 'tr>td', text: 3.to_s, count: 2
    assert_select 'tr>td', text: 4.to_s, count: 2
    assert_select 'tr>td', text: 5.to_s, count: 2
    assert_select 'tr>td', text: 6.to_s, count: 2
    assert_select 'tr>td', text: 7.to_s, count: 2
    assert_select 'tr>td', text: 8.to_s, count: 2
    assert_select 'tr>td', text: 9.to_s, count: 2
    assert_select 'tr>td', text: false.to_s, count: 2
    assert_select 'tr>td', text: 10.to_s, count: 2
    assert_select 'tr>td', text: false.to_s, count: 2
    assert_select 'tr>td', text: 11.to_s, count: 2
    assert_select 'tr>td', text: false.to_s, count: 2
    assert_select 'tr>td', text: 'Vco Group'.to_s, count: 2
    assert_select 'tr>td', text: false.to_s, count: 2
    assert_select 'tr>td', text: false.to_s, count: 2
    assert_select 'tr>td', text: false.to_s, count: 2
    assert_select 'tr>td', text: 'Lfo Wave'.to_s, count: 2
    assert_select 'tr>td', text: 'Vco1 Wave'.to_s, count: 2
    assert_select 'tr>td', text: 'Vco2 Wave'.to_s, count: 2
    assert_select 'tr>td', text: 'Vco3 Wave'.to_s, count: 2
    assert_select 'tr>td', text: false.to_s, count: 2
    assert_select 'tr>td', text: false.to_s, count: 2
    assert_select 'tr>td', text: ''.to_s, count: 2
    assert_select 'tr>td', text: 'Type'.to_s, count: 2
  end
end
