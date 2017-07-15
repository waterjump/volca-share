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
    expect(page).to have_content('Use the VCO Group selector to change the number of sequences.')

    click_button 'Save'

    reflects_patch(dummy_patch)
    expect(current_path).to eq("/user/#{user.slug}/patch/#{dummy_patch.slug}")
    expect(page).to have_title("#{dummy_patch.name} by #{user.username} | VolcaShare")
    expect(page).to have_selector 'h1', text: "#{dummy_patch.name} by #{user.username}", visible: false
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
    find('#vco_group_one_light').click

    click_link 'Add sequences'
    expect(page).to have_selector('.sequence-box', count: 3)
    expect(page).not_to have_link 'Add sequences'
    expect(page).to have_link 'Remove sequences'
    page.find('label[for=patch_sequences_attributes_0_step_1_step_mode]').trigger('click')
    page.find('label[for=patch_sequences_attributes_1_step_2_slide]').trigger('click')
    page.find('label[for=patch_sequences_attributes_2_step_3_active_step]').trigger('click')

    click_button 'Save'
    expect(Patch.first.sequences.count).to eq(3)
    expect(page).to       have_selector('.sequence-box', count: 3)
    expect(page).not_to   have_css('#patch_sequences_0_step_1_step_mode_light.lit')
    expect(page).to       have_css('#patch_sequences_1_step_2_slide_light.lit')
    expect(page).not_to   have_css('#patch_sequences_2_step_3_active_step_light.lit')
  end

  scenario 'are limited to two when VCO group two is selected' do
    click_link 'new-patch'
    expect(current_path).to eq(new_patch_path)

    dummy_patch = FactoryGirl.build(:patch)
    fill_out_patch_form(dummy_patch, true)
    find('#vco_group_two_light').click

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
    find('#vco_group_three_light').click

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

    dummy_patch = FactoryGirl.build(:patch)
    fill_out_patch_form(dummy_patch, true)
    find('#vco_group_three_light').click
    click_link 'Add sequences'
    expect(page).to have_selector('.sequence-box', count: 1)

    page.find('#patch_sequences_attributes_0_step_1_note_display')
        .drag_to(seq_form_light(0, 1, 'slide'))
    seq_form_light(0, 1, 'slide').trigger('click')
    seq_form_light(0, 5, 'slide').trigger('click')
    seq_form_light(0, 6, 'slide').trigger('click')
    seq_form_light(0, 9, 'slide').trigger('click')
    seq_form_light(0, 10, 'slide').trigger('click')
    seq_form_light(0, 11, 'slide').trigger('click')
    seq_form_light(0, 13, 'slide').trigger('click')
    seq_form_light(0, 14, 'slide').trigger('click')
    seq_form_light(0, 15, 'slide').trigger('click')
    seq_form_light(0, 16, 'slide').trigger('click')

    seq_form_light(0, 3, 'step_mode').trigger('click')
    seq_form_light(0, 7, 'step_mode').trigger('click')
    seq_form_light(0, 11, 'step_mode').trigger('click')
    seq_form_light(0, 15, 'step_mode').trigger('click')

    click_button 'Save'
    expect(page).to have_selector('.sequence-show')
    expect(page.find('#patch_sequences_attributes_0_step_1_note_display').text).to eq('G#2')
    expect(page).to have_css('#patch_sequences_0_step_1_slide_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_5_slide_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_6_slide_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_9_slide_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_10_slide_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_11_slide_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_13_slide_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_14_slide_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_15_slide_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_16_slide_light.lit')

    expect(page).to have_css('#patch_sequences_0_step_1_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_2_step_mode_light.lit')
    expect(page).not_to have_css('#patch_sequences_0_step_3_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_4_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_5_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_6_step_mode_light.lit')
    expect(page).not_to have_css('#patch_sequences_0_step_7_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_8_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_9_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_10_step_mode_light.lit')
    expect(page).not_to have_css('#patch_sequences_0_step_11_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_12_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_13_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_14_step_mode_light.lit')
    expect(page).not_to have_css('#patch_sequences_0_step_15_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_16_step_mode_light.lit')
  end

  scenario 'can be edited' do
    login

    visit root_path
    expect(page).to have_link 'New Patch'

    click_link 'new-patch'

    dummy_patch = FactoryGirl.build(:patch)

    fill_out_patch_form(dummy_patch)
    find('#vco_group_two_light').click
    expect(page).to have_link('Add sequences')

    click_link 'Add sequences'
    expect(page).to have_selector('.sequence-form')
    seq_form_light(0, 1, 'step_mode').trigger('click')
    seq_form_light(1, 2, 'slide').trigger('click')

    click_button 'Save'
    expect(page).to have_link('Edit')

    click_link 'Edit'
    expect(page).to have_selector('.sequence-form')
    expect(page).not_to have_selector('#patch_sequences_attributes_0_step_1_step_mode_light.lit')
    expect(page).to have_selector('#patch_sequences_attributes_1_step_2_slide_light.lit')
  end

  scenario 'can be decremented' do
    steps_1 = []
    steps_2 = []

    16.times do |index|
      steps_1 << create(:step, index: index + 1)
      steps_2 << create(:step, index: index + 1)
    end

    sequence_1 = create(:sequence, steps: steps_1)
    sequence_2 = create(:sequence, steps: steps_2)

    patch = FactoryGirl.create(
      :patch,
      name: '666',
      user_id: user.id,
      sequences: [sequence_1, sequence_2]
    )

    login
    visit patch_path(patch)
    expect(page).to have_link('Edit')

    click_link 'Edit'
    expect(page).to have_selector('.sequence-box', count: 2)
    find('#vco_group_three_light').click

    click_button 'Save'
    patch = Patch.find_by(name: '666')
    expect(patch.sequences.count).to eq(1)
    expect(patch.sequences.first.steps.count).to eq(16)
    expect(page).to have_selector('.sequence-box', count: 1)
  end

  scenario 'can be ignored before persisted' do
    click_link 'new-patch'
    expect(current_path).to eq(new_patch_path)

    dummy_patch = FactoryGirl.build(:patch)
    fill_out_patch_form(dummy_patch, true)
    find('#vco_group_two_light').click
    click_link 'Add sequences'

    expect(page).to have_selector('.sequence-box', count: 2)
    find('#vco_group_three_light').click

    click_button 'Save'
    patch = Patch.where(name: dummy_patch.name).first
    expect(patch.sequences.count).to eq(1)
    expect(page).to have_selector('.sequence-box', count: 1)
  end

  scenario 'can be added on edit' do
    login
    click_link 'new-patch'
    expect(current_path).to eq(new_patch_path)

    dummy_patch = FactoryGirl.build(:patch, vco_group: 'two')
    fill_out_patch_form(dummy_patch, true)
    click_button 'Save'
    visit edit_patch_path(Patch.last)

    expect(page).not_to have_selector('.sequence-box')
    expect(page).to have_link('Add sequences')

    click_link('Add sequences')

    expect(page).not_to have_selector('.sequence-box', count: 1)

    page.find('#patch_sequences_attributes_0_step_1_note_display')
        .drag_to(seq_form_light(0, 1, 'slide'))
    seq_form_light(0, 1, 'slide').trigger('click')
    seq_form_light(0, 5, 'slide').trigger('click')
    seq_form_light(0, 13, 'slide').trigger('click')
    seq_form_light(0, 16, 'slide').trigger('click')
    seq_form_light(0, 7, 'step_mode').trigger('click')

    click_button 'Save'
    expect(page).to have_selector('.sequence-show')
    expect(page.find('#patch_sequences_attributes_0_step_1_note_display').text).to eq('E2')
    expect(page).to have_css('#patch_sequences_0_step_1_slide_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_5_slide_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_13_slide_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_16_slide_light.lit')

    expect(page).to have_css('#patch_sequences_0_step_1_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_2_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_3_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_4_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_5_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_6_step_mode_light.lit')
    expect(page).not_to have_css('#patch_sequences_0_step_7_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_8_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_9_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_10_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_11_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_12_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_13_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_14_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_15_step_mode_light.lit')
    expect(page).to have_css('#patch_sequences_0_step_16_step_mode_light.lit')
  end

  scenario 'can be deleted' do
    steps_1 = []
    steps_2 = []

    16.times do |index|
      steps_1 << create(:step, index: index + 1)
      steps_2 << create(:step, index: index + 1)
    end

    sequence_1 = create(:sequence, steps: steps_1)
    sequence_2 = create(:sequence, steps: steps_2)

    patch = FactoryGirl.create(
      :patch,
      name: '666',
      user_id: user.id,
      sequences: [sequence_1, sequence_2]
    )

    login
    visit patch_path(patch)
    expect(page).to have_link('Edit')

    click_link 'Edit'
    expect(page).to have_selector('.sequence-box', count: 2)
    click_link 'Remove sequences'

    click_button 'Save'
    patch = Patch.find_by(name: '666')
    expect(patch.sequences.count).to eq(0)
    expect(page).not_to have_selector('.sequence-box')
  end

  scenario 'count changes accurately 1' do
    steps_1 = []

    16.times do |index|
      steps_1 << create(:step, index: index + 1)
    end

    sequence_1 = create(:sequence, steps: steps_1)

    patch = FactoryGirl.create(
      :patch,
      name: '666',
      user_id: user.id,
      sequences: [sequence_1]
    )

    login
    visit patch_path(patch)
    expect(page).to have_link('Edit')

    click_link 'Edit'
    expect(page).to have_selector('.sequence-box', count: 1)
    click_link 'Remove sequences'

    find('#vco_group_one_light').click
    click_link 'Add sequences'
    expect(page).to have_selector('.sequence-box', count: 3)

    click_button 'Save'
    patch = Patch.find_by(name: '666')
    expect(patch.sequences.count).to eq(3)
    expect(page).to have_selector('.sequence-box', count: 3)
  end

  scenario 'count changes accurately 2' do
    steps_1 = []

    16.times do |index|
      steps_1 << create(:step, index: index + 1)
    end

    sequence_1 = create(:sequence, steps: steps_1)

    patch = FactoryGirl.create(
      :patch,
      name: '666',
      user_id: user.id,
      sequences: [sequence_1]
    )

    login
    visit patch_path(patch)
    expect(page).to have_link('Edit')

    click_link 'Edit'
    expect(page).to have_selector('.sequence-box', count: 1)

    click_link 'Remove sequences'
    find('#vco_group_one_light').click
    click_link 'Add sequences'
    expect(page).to have_selector('.sequence-box', count: 3)
    find('#vco_group_two_light').click
    expect(page).to have_selector('.sequence-form', count: 3)
    expect(page.all('.sequence-area .remove-sequence', visible: false).last.value).to eq('true')

    click_button 'Save'
    patch = Patch.find_by(name: '666')
    expect(patch.sequences.count).to eq(2)
    expect(page).to have_selector('.sequence-box', count: 2)
  end
end
