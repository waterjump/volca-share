require 'rails_helper'

RSpec.feature 'patches', type: :feature, js: true do

  def range_select(name, value)
    selector = %-input[type=range][name=\\"#{name}\\"]-
    script = %-$("#{selector}").val(#{value})-
    page.execute_script(script)
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
    fill_in 'patch[name]', with: 'My Cool Patch'
    check 'patch[secret]' unless anon
    fill_in 'patch[notes]', with: 'This patch is cool.'
  end

  let(:user) { FactoryGirl.create(:user) }

  before(:each) { visit root_path }

  scenario 'can be created by users' do
    click_link 'Log in'
    fill_in 'user[email]', with: user.email
    fill_in 'user[password]', with: user.password
    click_button 'Log in'

    visit root_path
    expect(page).to have_link 'New Patch'

    click_link 'new-patch'

    expect(current_path).to eq(new_patch_path)
    expect(page.status_code).to eq(200)

    bottom_row = '#patch_form > div.stretchy.col-lg-9 > div > div.bottom-row'
    expect(
      page.find("#{bottom_row} > label:nth-child(6) > span > div")['data-active']
    ).not_to eq(nil) # vco_group 3
    expect(
      page.find("#{bottom_row} > label:nth-child(15) > span > div")['data-active']
    ).not_to eq(nil) # lfo_target_cutoff
    expect(
      page.find("#{bottom_row} > label:nth-child(27) > span > div")['data-active'])
    .not_to eq(nil) #vco3_wave

    dummy_patch = FactoryGirl.create(:patch)

    fill_out_patch_form(dummy_patch)

    expect(page).to have_css('.bootstrap-tagsinput')
    click_button 'Save'

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
    expect(page.find("#{bottom_row} > label:nth-child(1) > span > div")['data-active']).to eq ('false')
    expect(page.find("#{bottom_row} > label:nth-child(2) > span > div")['data-active']).to eq ('true')
    expect(page.find("#{bottom_row} > label:nth-child(3) > span > div")['data-active']).to eq ('false')
    expect(page.find("#{bottom_row} > label:nth-child(4) > span > div")['data-active']).to eq ('true')
    expect(page.find("#{bottom_row} > label:nth-child(5) > span > div")['data-active']).to eq ('true')
    expect(page.find("#{bottom_row} > label:nth-child(6) > span > div")['data-active']).to eq ('false')
    expect(page.find("#{bottom_row} > label:nth-child(7) > span > div")['data-active']).to eq ('true')
    expect(page.find("#{bottom_row} > label:nth-child(8) > span > div")['data-active']).to eq ('true')
    expect(page.find("#{bottom_row} > label:nth-child(9) > span > div")['data-active']).to eq ('true')
    expect(page.find("#{bottom_row} > label:nth-child(10) > span > div")['data-active']).to eq ('false')
    expect(page.find("#{bottom_row} > label:nth-child(11) > span > div")['data-active']).to eq ('true')
    expect(page.find("#{bottom_row} > label:nth-child(12) > span > div")['data-active']).to eq ('true')
    expect(page).to have_content('My Cool Patch')
    expect(page).to have_content('This patch is cool.')

    expect(page).to have_css('.volca')
    expect(page).to have_content("by #{user.username}")
    expect(page).to have_link('Edit')
    expect(page).to have_button('Delete')
  end

  scenario 'can be created by anonymous users' do
    visit root_path
    expect(page).to have_link 'New Patch'

    click_link 'new-patch'

    expect(current_path).to eq(new_patch_path)
    expect(page.status_code).to eq(200)
    expect(page).not_to have_content('Secret?')
    bottom_row = '#patch_form > div.stretchy.col-lg-9 > div > div.bottom-row'
    expect(
      page.find("#{bottom_row} > label:nth-child(6) > span > div")['data-active']
    ).not_to eq(nil) # vco_group 3
    expect(
      page.find("#{bottom_row} > label:nth-child(15) > span > div")['data-active']
    ).not_to eq(nil) # lfo_target_cutoff
    expect(
      page.find("#{bottom_row} > label:nth-child(27) > span > div")['data-active'])
    .not_to eq(nil) #vco3_wave

    dummy_patch = FactoryGirl.create(:patch)

    fill_out_patch_form(dummy_patch, true)

    expect(page).to have_css('.bootstrap-tagsinput')
    click_button 'Save'

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
    expect(page.find("#{bottom_row} > label:nth-child(1) > span > div")['data-active']).to eq ('false')
    expect(page.find("#{bottom_row} > label:nth-child(2) > span > div")['data-active']).to eq ('true')
    expect(page.find("#{bottom_row} > label:nth-child(3) > span > div")['data-active']).to eq ('false')
    expect(page.find("#{bottom_row} > label:nth-child(4) > span > div")['data-active']).to eq ('true')
    expect(page.find("#{bottom_row} > label:nth-child(5) > span > div")['data-active']).to eq ('true')
    expect(page.find("#{bottom_row} > label:nth-child(6) > span > div")['data-active']).to eq ('false')
    expect(page.find("#{bottom_row} > label:nth-child(7) > span > div")['data-active']).to eq ('true')
    expect(page.find("#{bottom_row} > label:nth-child(8) > span > div")['data-active']).to eq ('true')
    expect(page.find("#{bottom_row} > label:nth-child(9) > span > div")['data-active']).to eq ('true')
    expect(page.find("#{bottom_row} > label:nth-child(10) > span > div")['data-active']).to eq ('false')
    expect(page.find("#{bottom_row} > label:nth-child(11) > span > div")['data-active']).to eq ('true')
    expect(page.find("#{bottom_row} > label:nth-child(12) > span > div")['data-active']).to eq ('true')
    expect(page).to have_content('My Cool Patch')
    expect(page).to have_content('This patch is cool.')
    expect(page).to have_css('.volca')
    expect(page).to have_content('by [anonymous]')
    expect(page).not_to have_link('Edit')
    expect(page).not_to have_button('Delete')
  end

  scenario 'can be deleted by author' do
    patch1 = FactoryGirl.create(:patch, secret: false, user_id: user.id)
    expect(user.patches.count).to eq(1)

    click_link 'Log in'
    fill_in 'user[email]', with: user.email
    fill_in 'user[password]', with: user.password
    click_button 'Log in'

    visit patch_path(patch1)
    expect(page).to have_button('Delete')

    click_button('Delete')
    user.reload
    expect(user.patches.count).to eq(0)

    visit patches_path
    expect(page).to have_content('No patches to show.')
  end

  scenario 'cannot be deleted by non-author' do
    patch1 = FactoryGirl.create(:patch, secret: false, user_id: user.id)
    user_2 = FactoryGirl.create(:user)

    click_link 'Log in'
    fill_in 'user[email]', with: user_2.email
    fill_in 'user[password]', with: user_2.password
    click_button 'Log in'

    visit patch_path(patch1)
    expect(page).not_to have_button('Delete')
  end

  scenario 'can be deleted by author on patch browse page' do
    FactoryGirl.create(:patch, secret: false, user_id: user.id)

    click_link 'Log in'
    fill_in 'user[email]', with: user.email
    fill_in 'user[password]', with: user.password
    click_button 'Log in'

    visit patches_path
    expect(page).to have_button('Delete')

    click_button('Delete')
    user.reload
    expect(user.patches.count).to eq(0)

    visit patches_path
    expect(page).to have_content('No patches to show.')
  end

  scenario 'cannot be deleted by non-author on patch browse page' do
    FactoryGirl.create(:patch, secret: false, user_id: user.id)
    user_2 = FactoryGirl.create(:user)

    click_link 'Log in'
    fill_in 'user[email]', with: user_2.email
    fill_in 'user[password]', with: user_2.password
    click_button 'Log in'

    visit patches_path
    expect(page).not_to have_button('Delete')
  end

  scenario 'that are private are not show on the index' do
    patch1 = FactoryGirl.create(:patch, secret: false, user_id: user.id)
    patch2 = FactoryGirl.create(:patch, secret: true, user_id: user.id)

    visit root_path

    expect(page).to have_content(patch1.name)
    expect(page).not_to have_content(patch2.name)
  end

  scenario 'that are anonymous are not show on the index' do
    patch1 = FactoryGirl.create(:patch, secret: false)

    visit root_path

    expect(page).not_to have_content(patch1.name)
  end

  scenario 'patches are paginated on index' do
    user = FactoryGirl.create(:user)
    first_patch = FactoryGirl.create(:patch, secret: false, user_id: user.id)
    30.times do
      FactoryGirl.create(:patch, secret: false, user_id: user.id)
    end
    last_patch = FactoryGirl.create(:patch, secret: false, user_id: user.id)

    visit patches_path
    expect(page).to have_content(last_patch.name)
    expect(page).not_to have_content(first_patch.name)
    expect(page).to have_selector('.pagination')
    expect(page).to have_selector('.patch-holder', count: 20)
    within '.pagination' do
      expect(page).to have_link('2')
      expect(page).not_to have_link('3')
    end

    click_link '2'
    expect(page).not_to have_content(last_patch.name)
    expect(page).to have_content(first_patch.name)
    expect(page).to have_selector('.pagination')
    expect(page).to have_selector('.patch-holder', count: 12)
    expect(page).to have_link('2')
  end

  scenario 'header is shown' do
    expect(page).to have_content(/VolcaShare/i)
  end

  scenario 'footer is shown' do
    expect(page).to have_content(/Sean Barrett/i)
  end
end
