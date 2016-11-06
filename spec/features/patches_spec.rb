require 'rails_helper'

RSpec.feature 'patches', type: :feature, js: true do

  def range_select(name, value)
    selector = %-input[type=range][name=\\"#{name}\\"]-
    script = %-$("#{selector}").val(#{value})-
    page.execute_script(script)
  end

  before(:each) { visit root_path }

  scenario 'can be created by users' do
    user = FactoryGirl.create(:user)

    click_link 'Log in'
    fill_in 'user[email]', with: user.email
    fill_in 'user[password]', with: user.password
    click_button 'Log in'

    visit root_path

    click_link 'Patches'
    expect(page).to have_link 'Submit a patch'

    click_link 'Submit a patch'
    expect(current_path).to eq(new_patch_path)
    expect(page.status_code).to eq(200)
    bottom_row = '#patch_form > div > div.stretchy > div > div.bottom-row'
    expect(
      page.find("#{bottom_row} > label:nth-child(6) > span > div")['data-active']
    ).not_to eq(nil) # vco_group 3
    expect(
      page.find("#{bottom_row} > label:nth-child(15) > span > div")['data-active']
    ).not_to eq(nil) # lfo_target_cutoff
    expect(
      page.find("#{bottom_row} > label:nth-child(27) > span > div")['data-active'])
    .not_to eq(nil) #vco3_wave

    range_select 'patch[attack]', 0
    range_select 'patch[decay_release]', 0
    range_select 'patch[cutoff_eg_int]', 0
    range_select 'patch[peak]', 0
    range_select 'patch[cutoff]', 0
    range_select 'patch[lfo_rate]', 0
    range_select 'patch[lfo_int]', 0
    range_select 'patch[vco1_pitch]', 0
    find('#vco1_active_button').click
    range_select 'patch[vco2_pitch]', 0
    find('#vco2_active_button').click
    range_select 'patch[vco3_pitch]', 0
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
    fill_in 'patch[name]', with: 'My Cool Patch'
    check 'patch[private]'
    fill_in 'patch[notes]', with: 'This patch is cool.'
    click_button 'Save'

    expect(page).to have_css('.volca')
  end

  scenario 'cannot be created by guests' do
    click_link 'Patches'
    click_link 'Submit a patch'
    expect(current_path).to eq(new_user_session_path)
    expect(page.status_code).to eq(200)
  end

  scenario 'header is shown' do
    expect(page).to have_content(/VolcaShare/i)
  end

  scenario 'footer is shown' do
    expect(page).to have_content(/Sean Barrett/i)
  end
end
