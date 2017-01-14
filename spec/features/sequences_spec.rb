require 'rails_helper'

RSpec.feature 'sequences', type: :feature, js: true do
  def range_select(name, value)
    selector = %(input[type=range][name=\\"#{name}\\"])
    script = %-$("#{selector}").val(#{value})-
    page.execute_script(script)
  end

  def perform_around
    VCR.use_cassette('oembed') do
      yield
    end
  end

  around(:each) do |example|
    perform_around(&example)
  end

  def fill_out_patch_form(dummy_patch, anon = false)
    bottom_row = '#patch_form > div.stretchy.col-lg-9 > div > div.bottom-row'
    range_select 'patch[attack]', dummy_patch.attack
    range_select 'patch[decay_release]', dummy_patch.decay_release
    range_select 'patch[cutoff_eg_int]', dummy_patch.cutoff_eg_int
    range_select 'patch[octave]', dummy_patch.octave
    range_select 'patch[peak]', dummy_patch.peak
    range_select 'patch[cutoff]', dummy_patch.cutoff
    range_select 'patch[lfo_rate]', dummy_patch.lfo_rate
    range_select 'patch[lfo_int]', dummy_patch.lfo_int
    range_select 'patch[vco1_pitch]', dummy_patch.vco1_pitch
    range_select 'patch[slide_time]', dummy_patch.slide_time
    range_select 'patch[expression]', dummy_patch.expression
    range_select 'patch[gate_time]', dummy_patch.gate_time
    find('#vco1_active_button').click
    range_select 'patch[vco2_pitch]', dummy_patch.vco2_pitch
    find('#vco2_active_button').click
    range_select 'patch[vco3_pitch]', dummy_patch.vco3_pitch
    find('#vco3_active_button').click
    find("#{bottom_row} > label:nth-child(4)").click  # vco_group_two
    find("#{bottom_row} > label:nth-child(9)").click  # lfo_target_amp
    find("#{bottom_row} > label:nth-child(12)").click # lfo_target_pitch
    find("#{bottom_row} > label:nth-child(15)").click # lfo_target_cutoff
    find("#{bottom_row} > label:nth-child(18)").click # lfo_wave
    find("#{bottom_row} > label:nth-child(21)").click # vco1_wave
    find("#{bottom_row} > label:nth-child(24)").click # vco2_wave
    find("#{bottom_row} > label:nth-child(27)").click # vco3_wave
    find("#{bottom_row} > label:nth-child(30)").click # sustain_on
    find("#{bottom_row} > label:nth-child(33)").click # amp_eg_on
    fill_in 'patch[name]', with: dummy_patch.name
    fill_in 'patch[notes]', with: dummy_patch.notes
    unless anon
      check 'patch[secret]'
      fill_in 'patch[audio_sample]', with: dummy_patch.audio_sample
    end
  end

  let(:user) { FactoryGirl.create(:user) }
  let(:bottom_row) { '#patch_form > div.stretchy.col-lg-9 > div > div.bottom-row' }

  before(:each) { visit root_path }

  scenario 'can be created by users' do
    login

    visit root_path
    expect(page).to have_link 'New Patch'

    click_link 'new-patch'
    expect(page).to have_title('New Patch | VolcaShare')
    expect(current_path).to eq(new_patch_path)
    expect(page.status_code).to eq(200)

    dummy_patch = FactoryGirl.build(
      :patch,
      name: 'My Cool Patch',
      notes: 'This patch is cool.'
    )

    fill_out_patch_form(dummy_patch)

    expect(page).to have_css('.bootstrap-tagsinput')
    expect(page).to have_link('Add sequences')

    click_link 'Add sequences'
    expect(page).to have_selector('.sequence-form')

    click_button 'Save'
    expect(current_path).to eq("/user/#{user.slug}/patch/#{dummy_patch.slug}")
    expect(page).to have_title("#{dummy_patch.name} by #{user.username} | VolcaShare")
    expect(page).to have_selector 'h1', text: "#{dummy_patch.name} by #{user.username}", visible: false

    bottom_row = 'body > div > div.stretchy.col-lg-9 > div > div.bottom-row'
    expect(page.find('#attack')['data-midi']).to eq(dummy_patch.attack.to_s)
    expect(page.find('#decay_release')['data-midi']).to eq(dummy_patch.decay_release.to_s)
    expect(page.find('#cutoff_eg_int')['data-midi']).to eq(dummy_patch.cutoff_eg_int.to_s)
    expect(page.find('#octave')['data-midi']).to eq(dummy_patch.octave.to_s)
    expect(page.find('#peak')['data-midi']).to eq(dummy_patch.peak.to_s)
    expect(page.find('#cutoff')['data-midi']).to eq(dummy_patch.cutoff.to_s)
    expect(page.find('#lfo_rate')['data-midi']).to eq(dummy_patch.lfo_rate.to_s)
    expect(page.find('#lfo_int')['data-midi']).to eq(dummy_patch.lfo_int.to_s)
    expect(page.find('#vco1_pitch')['data-midi']).to eq(dummy_patch.vco1_pitch.to_s)
    expect(page.find('#vco2_pitch')['data-midi']).to eq(dummy_patch.vco2_pitch.to_s)
    expect(page.find('#vco3_pitch')['data-midi']).to eq(dummy_patch.vco3_pitch.to_s)
    expect(page.find('#slide_time', visible: false)['data-midi']).to eq(dummy_patch.slide_time.to_s)
    expect(page.find('#expression', visible: false)['data-midi']).to eq(dummy_patch.expression.to_s)
    expect(page.find('#gate_time', visible: false)['data-midi']).to eq(dummy_patch.gate_time.to_s)
    expect(page.find('#vco1_active_button')['data-active']).to eq('false')
    expect(page.find('#vco2_active_button')['data-active']).to eq('false')
    expect(page.find('#vco2_active_button')['data-active']).to eq('false')
    expect(page.find('#vco1_active_button')['data-active']).to eq('false')
    expect(page.find("#{bottom_row} > label:nth-child(1) > span > div")['data-active']).to eq 'false'
    expect(page.find("#{bottom_row} > label:nth-child(2) > span > div")['data-active']).to eq 'true'
    expect(page.find("#{bottom_row} > label:nth-child(3) > span > div")['data-active']).to eq 'false'
    expect(page.find("#{bottom_row} > label:nth-child(4) > span > div")['data-active']).to eq 'true'
    expect(page.find("#{bottom_row} > label:nth-child(5) > span > div")['data-active']).to eq 'true'
    expect(page.find("#{bottom_row} > label:nth-child(6) > span > div")['data-active']).to eq 'false'
    expect(page.find("#{bottom_row} > label:nth-child(7) > span > div")['data-active']).to eq 'true'
    expect(page.find("#{bottom_row} > label:nth-child(8) > span > div")['data-active']).to eq 'true'
    expect(page.find("#{bottom_row} > label:nth-child(9) > span > div")['data-active']).to eq 'true'
    expect(page.find("#{bottom_row} > label:nth-child(10) > span > div")['data-active']).to eq 'false'
    expect(page.find("#{bottom_row} > label:nth-child(11) > span > div")['data-active']).to eq 'true'
    expect(page.find("#{bottom_row} > label:nth-child(12) > span > div")['data-active']).to eq 'true'
    expect(page).to have_content(dummy_patch.name)
    expect(page).to have_content(dummy_patch.notes)

    expect(page).to have_selector('.sequence-show')

    expect(page).to have_css('.volca')
    expect(page).to have_content("by #{user.username}")
    expect(page).to have_link('Edit')
    expect(page).to have_button('Delete')
  end

  scenario 'are limited to three when VCO group one is selected' do
    click_link 'new-patch'
    expect(current_path).to eq(new_patch_path)

    find("#{bottom_row} > label:nth-child(2)").click  # vco_group_one

    click_link 'Add sequences'
    expect(page).to have_selector('.sequence-box', count: 3)
    expect(page).not_to have_link 'Add sequences'
    expect(page).to have_link 'Remove sequences'
  end

  scenario 'are limited to two when VCO group two is selected' do
    click_link 'new-patch'
    expect(current_path).to eq(new_patch_path)

    find("#{bottom_row} > label:nth-child(4)").click  # vco_group_two

    click_link 'Add sequences'
    expect(page).to have_selector('.sequence-box', count: 2)
    expect(page).not_to have_link 'Add sequences'
    expect(page).to have_link 'Remove sequences'
  end

  scenario 'are limited to one when VCO group three is selected' do
    click_link 'new-patch'
    expect(current_path).to eq(new_patch_path)

    click_link 'Add sequences'
    expect(page).to have_selector('.sequence-box', count: 1)
    expect(page).not_to have_link 'Add sequences'
    expect(page).to have_link 'Remove sequences'
  end

  scenario 'are shown after the patch is saved' do
    click_link 'new-patch'
    expect(current_path).to eq(new_patch_path)

    click_link 'Add sequences'
    expect(page).to have_selector('.sequence-box', count: 1)

    dummy_patch = FactoryGirl.build(:patch)
    fill_out_patch_form(dummy_patch, true)
    page.find('label[for=patch_sequences__step_1_step_mode]').trigger('click');
    page.find('label[for=patch_sequences__step_2_slide]').trigger('click');
    page.find('label[for=patch_sequences__step_3_active_step]').trigger('click');

    click_button 'Save'
    expect(page).to have_selector('.sequence-show')
    expect(page.find('#patch_sequences__step_1_step_mode_light')).not_to have_css('lit')
    expect(page.find('#patch_sequences__step_2_slide_light')['data-active']).to eq('true')
    expect(page.find('#patch_sequences__step_3_active_step_light')).not_to have_css('lit')
  end
end
