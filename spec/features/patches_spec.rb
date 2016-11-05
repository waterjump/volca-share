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
    bottom_row = '#new_patch > div > div.stretchy > div > div.bottom-row'
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

    expect(page).to have_content('Patch was successfully created.')
    expect(page.status_code).to eq(200)
    expect(page).to have_content('Name: My Cool Patch')
    expect(page).to have_content('Attack: 0')
    expect(page).to have_content('Decay release: 0')
    expect(page).to have_content('Cutoff eg int: 0')
    expect(page).to have_content('Peak: 0')
    expect(page).to have_content('Cutoff: 0')
    expect(page).to have_content('Lfo rate: 0')
    expect(page).to have_content('Lfo int: 0')
    expect(page).to have_content('Vco1 pitch: 0')
    expect(page).to have_content('Vco1 on: false')
    expect(page).to have_content('Vco2 pitch: 0')
    expect(page).to have_content('vco2 on: false')
    expect(page).to have_content('Vco3 pitch: 0')
    expect(page).to have_content('Vco3 on: false')
    expect(page).to have_content('Vco group: two')
    expect(page).to have_content('Lfo target amp: true')
    expect(page).to have_content('Lfo target pitch: true')
    expect(page).to have_content('Lfo target cutoff: false')
    expect(page).to have_content('Lfo wave: square')
    expect(page).to have_content('Vco1 wave: square')
    expect(page).to have_content('Vco2 wave: square')
    expect(page).to have_content('Vco3 wave: saw')
    expect(page).to have_content('Sustain on: true')
    expect(page).to have_content('Amp eg on: true')
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
