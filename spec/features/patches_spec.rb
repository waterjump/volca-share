require 'rails_helper'

RSpec.feature 'patches', type: :feature, js: true do
  def perform_around
    VCR.use_cassette('oembed') do
      yield
    end
  end

  around(:each) do |example|
    perform_around(&example)
  end

  let(:user) { FactoryGirl.create(:user) }

  before(:each) { visit root_path }

  scenario 'have initialized values' do
    click_link 'new-patch'
    expect(page.find('#vco_group_three_light')['data-active']).not_to eq(nil)
    expect(page.find('#lfo_target_cutoff_light')['data-active']).not_to eq(nil)
    expect(page.find('#vco3_wave_light')['data-active']).not_to eq(nil)
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
    expect(page.find('#vco_group_one_light')['data-active']).to eq('false')
    expect(page.find('#vco_group_two_light')['data-active']).to eq('true')
    expect(page.find('#vco_group_three_light')['data-active']).to eq('false')
    expect(page.find('#lfo_target_amp_light')['data-active']).to eq 'true'
    expect(page.find('#lfo_target_pitch_light')['data-active']).to eq 'true'
    expect(page.find('#lfo_target_cutoff_light')['data-active']).to eq 'false'
    expect(page.find('#lfo_wave_light')['data-active']).to eq 'true'
    expect(page.find('#vco1_wave_light')['data-active']).to eq 'true'
    expect(page.find('#vco2_wave_light')['data-active']).to eq 'true'
    expect(page.find('#vco3_wave_light')['data-active']).to eq 'false'
    expect(page.find('#sustain_on_light')['data-active']).to eq 'true'
    expect(page.find('#amp_eg_on_light ')['data-active']).to eq 'true'
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
    expect(page.find('#vco_group_one_light')['data-active']).to eq 'false'
    expect(page.find('#vco_group_two_light')['data-active']).to eq 'true'
    expect(page.find('#vco_group_three_light')['data-active']).to eq 'false'
    expect(page.find('#lfo_target_amp_light')['data-active']).to eq 'true'
    expect(page.find('#lfo_target_pitch_light')['data-active']).to eq 'true'
    expect(page.find('#lfo_target_cutoff_light')['data-active']).to eq 'false'
    expect(page.find('#lfo_wave_light')['data-active']).to eq 'true'
    expect(page.find('#vco1_wave_light')['data-active']).to eq 'true'
    expect(page.find('#vco2_wave_light')['data-active']).to eq 'true'
    expect(page.find('#vco3_wave_light')['data-active']).to eq 'false'
    expect(page.find('#sustain_on_light')['data-active']).to eq 'true'
    expect(page.find('#amp_eg_on_light')['data-active']).to eq 'true'
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
    expect(page.body).to have_content('Patch saved successfully.')

    # Freesound
    visit edit_patch_path(patch.slug)
    fill_in 'patch[audio_sample]', with: 'https://freesound.org/people/volcashare/sounds/123456'
    click_button 'Save'
    expect(page.body).to have_content('Patch saved successfully.')
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

    random_patch = {
      attack: page.find('#attack')['data-midi'],
      cutoff: page.find('#cutoff')['data-midi'],
      gate_time: page.find('#gate_time', visible: false)['data-midi'],
      lfo_target_pitch: page.find('#lfo_target_pitch_light')['data-active'],
      vco3_active: page.find('#vco3_active_button')['data-active']
    }

    expect(random_patch).not_to eq(default_patch)

    visit patch_path(Patch.first)
    expect(page).not_to have_selector('#randomize')

    visit edit_patch_path(Patch.first)
    expect(page).not_to have_selector('#randomize')
  end

  scenario 'do not randomize midi-only-controls if midi not available' do
    visit new_patch_path
    expect(page).to have_link('randomize')

    click_link 'randomize'
    default_patch = {
      attack: '63',
      cutoff: '63',
      lfo_target_pitch: '',
      vco3_active: 'true',
      slide_time: '63',
      expression: '127',
      gate_time: '127'
    }

    fill_in 'patch[name]', with: 'Schnackenpfefferhausen'
    click_button 'Save'

    random_patch = {
      attack: page.find('#attack')['data-midi'],
      cutoff: page.find('#cutoff')['data-midi'],
      lfo_target_pitch: page.find('#lfo_target_pitch_light')['data-active'],
      vco3_active: page.find('#vco3_active_button')['data-active'],
      slide_time: page.find('#slide_time', visible: false)['data-midi'],
      expression: page.find('#expression', visible: false)['data-midi'],
      gate_time: page.find('#gate_time', visible: false)['data-midi']
    }

    expect(random_patch).not_to eq(default_patch)
    expect(random_patch.slice(:slide_time, :expression, :gate_time))
      .to eq default_patch.slice(:slide_time, :expression, :gate_time)
  end

  scenario 'that have sequences do not randomize vco groups' do
    visit new_patch_path
    expect(page).to have_link('randomize')
    click_link 'Add sequences'

    click_link 'randomize'
    default_patch = {
      attack: '63',
      cutoff: '63',
      gate_time: '127',
      lfo_target_pitch: '',
      vco_group_3: 'true',
      vco_group_2: 'false',
      vco_group_1: 'false'
    }

    fill_in 'patch[name]', with: 'Joey Joe Joe Junior Shabadoo'
    click_button 'Save'

    random_patch = {
      attack: page.find('#attack')['data-midi'],
      cutoff: page.find('#cutoff')['data-midi'],
      gate_time: page.find('#gate_time', visible: false)['data-midi'],
      lfo_target_pitch: page.find('#lfo_target_pitch_light')['data-active'],
      vco_group_3: page.find('#vco_group_three_light')['data-active'],
      vco_group_2: page.find('#vco_group_two_light')['data-active'],
      vco_group_1: page.find('#vco_group_one_light')['data-active']
    }

    expect(random_patch).not_to eq(default_patch)
    expect(random_patch[:vco_group_3]).to eq(default_patch[:vco_group_3])
    expect(random_patch[:vco2_active]).to eq(default_patch[:vco2_active])
    expect(random_patch[:vco1_active]).to eq(default_patch[:vco1_active])
    expect(page).to have_selector('.sequence-show', count: 1)
  end
end
