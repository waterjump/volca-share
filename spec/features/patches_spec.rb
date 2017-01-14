require 'rails_helper'

RSpec.feature 'patches', type: :feature, js: true do
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

  before(:each) { visit root_path }

  scenario 'have initialized values' do
    click_link 'new-patch'
    bottom_row = '#patch_form > div.stretchy.col-lg-9 > div > div.bottom-row'
    expect(
      page.find("#{bottom_row} > label:nth-child(6) > span > div")['data-active']
    ).not_to eq(nil) # vco_group 3
    expect(
      page.find("#{bottom_row} > label:nth-child(15) > span > div")['data-active']
    ).not_to eq(nil) # lfo_target_cutoff
    expect(
      page.find("#{bottom_row} > label:nth-child(27) > span > div")['data-active']
    )
      .not_to eq(nil) # vco3_wave
  end

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

    dummy_patch = FactoryGirl.build(:patch)

    fill_out_patch_form(dummy_patch, true)

    expect(page).to have_css('.bootstrap-tagsinput')
    click_button 'Save'

    expect(page).to have_selector 'h1', text: "#{dummy_patch.name} by ¯\\_(ツ)_/¯", visible: false
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
    expect(page).to have_css('.volca')
    expect(page).to have_content('by ¯\_(ツ)_/¯')
    expect(page).not_to have_link('Edit')
    expect(page).not_to have_button('Delete')
  end

  scenario 'can be deleted by author' do
    patch1 = FactoryGirl.create(:patch, secret: false, user_id: user.id)
    expect(user.patches.count).to eq(1)

    login

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

    login(user_2)

    visit patch_path(patch1)
    expect(page).not_to have_button('Delete')
  end

  scenario 'header is shown' do
    expect(page).to have_content(/VolcaShare/i)
  end

  scenario 'footer is shown' do
    expect(page).to have_content(/Sean Barrett/i)
  end

  scenario 'audio samples are limited to soundcloud, freesound, and youtube' do
    patch = FactoryGirl.create(:patch, user_id: user.id, secret: false)
    login

    visit edit_patch_path(patch.slug)
    expect(current_path).to eq(edit_patch_path(patch.slug))
    expect(page.status_code).to eq(200)

    fill_in 'patch[audio_sample]', with: 'https://somewebsite.edu/69bot/shallow'
    click_button 'Save'
    expect(page).to have_content('Audio sample needs to be direct SoundCloud, Freesound or YouTube link.')

    # YouTube
    fill_in 'patch[audio_sample]', with: 'https://youtube.com/watch?v=GF60Iuh643I'
    click_button 'Save'
    expect(page).to have_content('Patch saved successfully.')

    # Freesound
    visit edit_patch_path(patch.slug)
    fill_in 'patch[audio_sample]', with: 'https://freesound.org/people/volcashare/sounds/123456'
    click_button 'Save'
    expect(page).to have_content('Patch saved successfully.')
  end

  scenario 'can be randomized' do
    visit new_patch_path
    expect(page).to have_link('randomize')

    click_link 'randomize'
    default_patch = {
      attack: '63',
      cutoff: '63',
      gate_time: '127',
      lfo_target_pitch: '',
      vco3_active: 'true'
    }

    fill_in 'patch[name]', with: 'Joey Joe Joe Junior Shabadoo'
    click_button 'Save'

    bottom_row = 'body > div > div.stretchy.col-lg-9 > div > div.bottom-row'

    random_patch = {
      attack: page.find('#attack')['data-midi'],
      cutoff: page.find('#cutoff')['data-midi'],
      gate_time: page.find('#gate_time', visible: false)['data-midi'],
      lfo_target_pitch: page.find("#{bottom_row} > label:nth-child(5) > span > div")['data-active'],
      vco3_active: page.find('#vco3_active_button')['data-active']
    }

    expect(random_patch).not_to eq(default_patch)

    visit patch_path(Patch.first)
    expect(page).not_to have_selector('#randomize')

    visit edit_patch_path(Patch.first)
    expect(page).not_to have_selector('#randomize')
  end
end
