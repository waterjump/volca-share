require 'rails_helper'

RSpec.describe 'patches/new', type: :view do
  before(:each) do
    assign(:patch, Patch.new(
                     name: 'MyString',
                     tempo: 1,
                     attack: 1,
                     decay_release: 1,
                     cutoff_eg_int: 1,
                     peak: 1,
                     cutoff: 1,
                     lfo_rate: 1,
                     lfo_int: 1,
                     vco1_pitch: 1,
                     vco1_active: false,
                     vco2_pitch: 1,
                     vco2_active: false,
                     vco3_pitch: 1,
                     vco3_active: false,
                     vco_group: 'MyString',
                     lfo_target_amp: false,
                     lfo_target_pitch: false,
                     lfo_target_cutoff: false,
                     lfo_wave: 'MyString',
                     vco1_wave: 'MyString',
                     vco2_wave: 'MyString',
                     vco3_wave: 'MyString',
                     sustain_on: false,
                     amp_eg_on: false,
                     tags: '',
                     type: ''
    ))
  end

  it 'renders new patch form' do
    render

    assert_select 'form[action=?][method=?]', patches_path, 'post' do
      assert_select 'input#patch_name[name=?]', 'patch[name]'

      assert_select 'input#patch_tempo[name=?]', 'patch[tempo]'

      assert_select 'input#patch_attack[name=?]', 'patch[attack]'

      assert_select 'input#patch_decay_release[name=?]', 'patch[decay_release]'

      assert_select 'input#patch_cutoff_eg_int[name=?]', 'patch[cutoff_eg_int]'

      assert_select 'input#patch_peak[name=?]', 'patch[peak]'

      assert_select 'input#patch_cutoff[name=?]', 'patch[cutoff]'

      assert_select 'input#patch_lfo_rate[name=?]', 'patch[lfo_rate]'

      assert_select 'input#patch_lfo_int[name=?]', 'patch[lfo_int]'

      assert_select 'input#patch_vco1_pitch[name=?]', 'patch[vco1_pitch]'

      assert_select 'input#patch_vco1_active[name=?]', 'patch[vco1_active]'

      assert_select 'input#patch_vco2_pitch[name=?]', 'patch[vco2_pitch]'

      assert_select 'input#patch_vco2_active[name=?]', 'patch[vco2_active]'

      assert_select 'input#patch_vco3_pitch[name=?]', 'patch[vco3_pitch]'

      assert_select 'input#patch_vco3_active[name=?]', 'patch[vco3_active]'

      assert_select 'input#patch_vco_group[name=?]', 'patch[vco_group]'

      assert_select 'input#patch_lfo_target_amp[name=?]', 'patch[lfo_target_amp]'

      assert_select 'input#patch_lfo_target_pitch[name=?]', 'patch[lfo_target_pitch]'

      assert_select 'input#patch_lfo_target_cutoff[name=?]', 'patch[lfo_target_cutoff]'

      assert_select 'input#patch_lfo_wave[name=?]', 'patch[lfo_wave]'

      assert_select 'input#patch_vco1_wave[name=?]', 'patch[vco1_wave]'

      assert_select 'input#patch_vco2_wave[name=?]', 'patch[vco2_wave]'

      assert_select 'input#patch_vco3_wave[name=?]', 'patch[vco3_wave]'

      assert_select 'input#patch_sustain_on[name=?]', 'patch[sustain_on]'

      assert_select 'input#patch_amp_eg_on[name=?]', 'patch[amp_eg_on]'

      assert_select 'input#patch_tags[name=?]', 'patch[tags]'

      assert_select 'input#patch_type[name=?]', 'patch[type]'
    end
  end
end
