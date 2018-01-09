require 'rails_helper'

RSpec.describe 'Sequences', type: :feature, js: true do
  let(:user) { FactoryBot.create(:user) }

  context 'when user is logged in' do
    it 'can be created' do
      login
      visit new_patch_path
      expect(page).to have_title('New Patch | VolcaShare')

      dummy_patch = FactoryBot.build(
        :patch,
        name: 'My Cool Patch',
        notes: 'This patch is cool.'
      )

      fill_out_patch_form(dummy_patch)

      click_link 'Add sequences'
      expect(page).to have_selector('.sequence-form')
      # TODO: move to view spec
      expect(page).to have_content('Use the VCO Group selector to change the number of sequences.')

      click_button 'Save'

      reflects_patch(dummy_patch)
      expect(current_path).to eq("/user/#{user.slug}/patch/#{dummy_patch.slug}")
      expect(page).to have_title("#{dummy_patch.name} by #{user.username} | VolcaShare")
      expect(page).to have_selector('.sequence-show')
    end
  end

  context 'when VCO group one is selected' do
    it 'is limited to three sequences' do
      visit new_patch_path

      dummy_patch = FactoryBot.build(:patch)
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
  end

  context 'when VCO group two is selected' do
    it 'is limited to two sequences' do
      visit new_patch_path

      dummy_patch = FactoryBot.build(:patch)
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
  end

  context 'when VCO group three is selected' do
    it 'is limited to one sequence' do
      visit new_patch_path

      dummy_patch = FactoryBot.build(:patch)
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
  end

  it 'shows sequences after the patch is saved' do
    visit new_patch_path

    dummy_patch = FactoryBot.build(:patch)
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

  describe 'patch show page sequence display' do
    it 'does not toggle light when clicked' do
      patch = FactoryBot.create(
        :patch_with_sequences,
        name: '666',
        user_id: user.id,
        sequence_count: 2
      )
      patch.sequences.first.steps.first.update(slide: true)

      login
      visit patch_path(patch)
      first('#patch_sequences_0_step_1_slide_light').trigger('click')
      expect(page).to have_css('#patch_sequences_0_step_1_slide_light.lit')
    end
  end

  scenario 'can be edited' do
    login
    visit new_patch_path

    dummy_patch = FactoryBot.build(:patch)

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
    patch = FactoryBot.create(
      :patch_with_sequences,
      name: '666',
      user_id: user.id,
      sequence_count: 2
    )

    login
    visit edit_patch_path(patch)

    expect(page).to have_selector('.sequence-box', count: 2)
    find('#vco_group_three_light').click

    click_button 'Save'
    patch = Patch.last
    expect(patch.sequences.count).to eq(1)
    expect(patch.sequences.first.steps.count).to eq(16)
    expect(page).to have_selector('.sequence-box', count: 1)
  end

  scenario 'can be ignored before persisted' do
    visit new_patch_path

    dummy_patch = FactoryBot.build(:patch)
    fill_out_patch_form(dummy_patch, true)
    find('#vco_group_two_light').click
    click_link 'Add sequences'

    expect(page).to have_selector('.sequence-box', count: 2)
    find('#vco_group_three_light').click

    click_button 'Save'
    patch = Patch.last
    # patch = Patch.where(name: dummy_patch.name).first
    expect(patch.sequences.count).to eq(1)
    expect(page).to have_selector('.sequence-box', count: 1)
  end

  scenario 'can be added on edit' do
    login
    visit new_patch_path

    dummy_patch = FactoryBot.build(:patch, vco_group: 'two')
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
    find('#patch_sequences_attributes_0_step_1_note_display').hover
    expect(page).to have_css('.note-7.lit')
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
    patch = FactoryBot.create(
      :patch_with_sequences,
      name: '666',
      user_id: user.id,
      sequence_count: 2
    )

    login
    visit edit_patch_path(patch)

    expect(page).to have_selector('.sequence-box', count: 2)
    click_link 'Remove sequences'

    click_button 'Save'
    patch = Patch.last
    expect(patch.sequences.count).to eq(0)
    expect(page).not_to have_selector('.sequence-box')
  end

  scenario 'count changes accurately 1' do
    patch = FactoryBot.create(
      :patch_with_sequences,
      name: '666',
      user_id: user.id,
      sequence_count: 1
    )

    login
    visit edit_patch_path(patch)

    expect(page).to have_selector('.sequence-box', count: 1)
    click_link 'Remove sequences'

    find('#vco_group_one_light').click
    click_link 'Add sequences'
    expect(page).to have_selector('.sequence-box', count: 3)

    click_button 'Save'
    patch = Patch.last
    expect(patch.sequences.count).to eq(3)
    expect(page).to have_selector('.sequence-box', count: 3)
  end

  scenario 'count changes accurately 2' do
    patch = FactoryBot.create(
      :patch_with_sequences,
      name: '666',
      user_id: user.id,
      sequence_count: 1
    )

    login
    visit edit_patch_path(patch)

    # TODO: move to view spec
    expect(page).to have_selector('.sequence-box', count: 1)

    click_link 'Remove sequences'
    find('#vco_group_one_light').click
    click_link 'Add sequences'
    expect(page).to have_selector('.sequence-box', count: 3)
    find('#vco_group_two_light').click
    expect(page).to have_selector('.sequence-form', count: 3)
    expect(page.all('.sequence-area .remove-sequence', visible: false).last.value).to eq('true')

    click_button 'Save'
    patch = Patch.last
    expect(patch.sequences.count).to eq(2)
    expect(page).to have_selector('.sequence-box', count: 2)
  end
end
