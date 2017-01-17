require 'rails_helper'

RSpec.feature 'sequences', type: :feature, js: true do
  def perform_around
    VCR.use_cassette('oembed') do
      yield
    end
  end

  around(:each) do |example|
    perform_around(&example)
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

    dummy_patch = FactoryGirl.build(:patch)
    fill_out_patch_form(dummy_patch, true)
    find("#{bottom_row} > label:nth-child(2)").click  # vco_group_one

    click_link 'Add sequences'
    expect(page).to have_selector('.sequence-box', count: 3)
    expect(page).not_to have_link 'Add sequences'
    expect(page).to have_link 'Remove sequences'
    page.find('label[for=patch_new_sequences_0_step_1_step_mode]').trigger('click')
    page.find('label[for=patch_new_sequences_1_step_2_slide]').trigger('click')
    page.find('label[for=patch_new_sequences_2_step_3_active_step]').trigger('click')

    click_button 'Save'
    expect(Patch.first.sequences.count).to eq(3)
    expect(page).to have_selector('.sequence-box', count: 3)
    expect(page.find('#patch_sequences_0_step_1_step_mode_light')).not_to have_css('lit')
    expect(page.find('#patch_sequences_1_step_2_slide_light')['data-active']).to eq('true')
    expect(page.find('#patch_sequences_2_step_3_active_step_light')).not_to have_css('lit')
  end

  scenario 'are limited to two when VCO group two is selected' do
    click_link 'new-patch'
    expect(current_path).to eq(new_patch_path)

    dummy_patch = FactoryGirl.build(:patch)
    fill_out_patch_form(dummy_patch, true)
    find("#{bottom_row} > label:nth-child(4)").click  # vco_group_two

    click_link 'Add sequences'
    expect(page).to have_selector('.sequence-box', count: 2)
    expect(page).not_to have_link 'Add sequences'
    expect(page).to have_link 'Remove sequences'

    click_button 'Save'
    expect(Patch.first.sequences.count).to eq(2)
    expect(page).to have_selector('.sequence-box', count: 2)
  end

  scenario 'are limited to one when VCO group three is selected' do
    click_link 'new-patch'
    expect(current_path).to eq(new_patch_path)

    dummy_patch = FactoryGirl.build(:patch)
    fill_out_patch_form(dummy_patch, true)
    find("#{bottom_row} > label:nth-child(6)").click  # vco_group_three

    click_link 'Add sequences'
    expect(page).to have_selector('.sequence-box', count: 1)
    expect(page).not_to have_link 'Add sequences'
    expect(page).to have_link 'Remove sequences'

    click_button 'Save'
    expect(Patch.first.sequences.count).to eq(1)
    expect(page).to have_selector('.sequence-box', count: 1)
  end

  scenario 'are shown after the patch is saved' do
    click_link 'new-patch'
    expect(current_path).to eq(new_patch_path)

    click_link 'Add sequences'
    expect(page).to have_selector('.sequence-box', count: 1)

    dummy_patch = FactoryGirl.build(:patch)
    fill_out_patch_form(dummy_patch, true)
    page.find('label[for=patch_new_sequences_0_step_1_step_mode]').trigger('click')
    page.find('label[for=patch_new_sequences_0_step_2_slide]').trigger('click')
    page.find('label[for=patch_new_sequences_0_step_3_active_step]').trigger('click')

    click_button 'Save'
    expect(page).to have_selector('.sequence-show')
    expect(page.find('#patch_sequences_0_step_1_step_mode_light')).not_to have_css('lit')
    expect(page.find('#patch_sequences_0_step_2_slide_light')['data-active']).to eq('true')
    expect(page.find('#patch_sequences_0_step_3_active_step_light')).not_to have_css('lit')
  end

  scenario 'can be edited' do
    login

    visit root_path
    expect(page).to have_link 'New Patch'

    click_link 'new-patch'

    dummy_patch = FactoryGirl.build(:patch)

    fill_out_patch_form(dummy_patch)
    find("#{bottom_row} > label:nth-child(4)").click  # vco_group_two
    expect(page).to have_link('Add sequences')

    click_link 'Add sequences'
    expect(page).to have_selector('.sequence-form')
    page.find('label[for=patch_new_sequences_0_step_1_step_mode]').trigger('click')
    page.find('label[for=patch_new_sequences_1_step_2_slide]').trigger('click')

    click_button 'Save'
    expect(page).to have_link('Edit')

    click_link 'Edit'
    expect(page).to have_selector('.sequence-form')
    expect(page.find('#patch_existing_sequences_0_step_1_step_mode_light')).not_to have_css('lit')
    expect(page.find('#patch_existing_sequences_1_step_2_step_mode_light')).not_to have_css('lit')
  end

  scenario 'can be deleted' do
    steps_1 = []
    steps_2 = []
    16.times do
      steps_1 << create(:step)
      steps_2 << create(:step)
    end

    sequence_1 = create(:sequence, steps: steps_1)
    sequence_2 = create(:sequence, steps: steps_2)

    patch = FactoryGirl.create(
      :patch,
      user_id: user.id,
      sequences: [sequence_1, sequence_2]
    )

    login
    visit patch_path(patch)
    expect(page).to have_link('Edit')

    click_link 'Edit'
    expect(page).to have_selector('.sequence-box', count: 2)
    expect(page).to have_selector('.remove-sequence', count: 2)
    page.first('.remove-sequence').trigger('click')

    click_button 'Save'
    expect(page).to have_selector('.sequence-box', count: 1)
  end
end
