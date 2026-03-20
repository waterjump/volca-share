# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bass patch index emulation', js: true do
  let!(:first_patch) { create(:user_patch, name: 'First Patch') }
  let!(:second_patch) { create(:user_patch, name: 'Second Patch') }

  def emulate_toggle_selector(patch)
    ".bass-emulate-toggle[data-patch-id='#{patch.id}']"
  end

  def patch_card_selector(patch, active_state)
    ".patch-holder[data-patch-id='#{patch.id}']" \
      "[data-emulation-active='#{active_state}']"
  end

  def emulate_toggle_for(patch)
    find(emulate_toggle_selector(patch), visible: :all)
  end

  def musical_typing_toggle
    find('#bass-musical-typing-toggle', visible: :all)
  end

  def musical_typing_container
    find('.bass-index-musical-typing', visible: :all)
  end

  def expect_patch_active(patch)
    expect(page).to have_css(patch_card_selector(patch, 'true'))
  end

  def expect_patch_inactive(patch)
    expect(page).to have_css(patch_card_selector(patch, 'false'))
  end

  def expect_toggle_pressed(patch)
    expect(page).to have_css(
      "#{emulate_toggle_selector(patch)}[aria-pressed='true']"
    )
  end

  def ordered_patches
    ordered_patch_ids = all(
      '.patch-holder',
      minimum: 2,
      visible: :all
    ).map do |card|
      card['data-patch-id']
    end

    [first_patch, second_patch].sort_by do |patch|
      ordered_patch_ids.index(patch.id.to_s) || ordered_patch_ids.length
    end
  end

  before do
    visit patches_path
  end

  it 'starts with no active emulation and hidden musical typing control' do
    expect(page).to have_css(
      ".patch-holder[data-emulation-active='false']",
      count: 2
    )
    expect(page).to have_css('.bass-emulate-toggle', count: 2)
    expect(musical_typing_container[:class]).to include('hidden')
    expect(musical_typing_toggle[:'aria-pressed']).to eq('false')
    expect(musical_typing_toggle).to be_disabled
  end

  it 'activates a patch and enables musical typing by default' do
    emulate_toggle_for(first_patch).click

    expect_patch_active(first_patch)
    expect_toggle_pressed(first_patch)
    expect(musical_typing_container[:class]).not_to include('hidden')
    expect(musical_typing_toggle).not_to be_disabled
    expect(musical_typing_toggle[:'aria-pressed']).to eq('true')
  end

  it 'switches the active emulation to the next patch card' do
    first_rendered_patch, second_rendered_patch = ordered_patches

    emulate_toggle_for(first_rendered_patch).click
    expect_patch_active(first_rendered_patch)
    expect_toggle_pressed(first_rendered_patch)

    emulate_toggle_for(second_rendered_patch).click

    expect_patch_inactive(first_rendered_patch)
    expect_patch_active(second_rendered_patch)
    expect_toggle_pressed(second_rendered_patch)
    expect(musical_typing_toggle[:'aria-pressed']).to eq('true')
  end

  it 'toggles the active patch off when clicked again' do
    emulate_toggle_for(first_patch).click
    expect_patch_active(first_patch)
    emulate_toggle_for(first_patch).click

    expect_patch_inactive(first_patch)
    expect(musical_typing_container[:class]).to include('hidden')
    expect(musical_typing_toggle[:'aria-pressed']).to eq('false')
    expect(musical_typing_toggle).to be_disabled
  end

  it 'stops the active emulation when escape is pressed' do
    emulate_toggle_for(first_patch).click
    expect_patch_active(first_patch)

    find('body').send_keys(:escape)

    expect_patch_inactive(first_patch)
    expect(musical_typing_container[:class]).to include('hidden')
    expect(musical_typing_toggle[:'aria-pressed']).to eq('false')
  end

  it 'moves to the next and previous patch with arrow keys' do
    first_rendered_patch, second_rendered_patch = ordered_patches

    emulate_toggle_for(first_rendered_patch).click
    expect_patch_active(first_rendered_patch)
    expect_toggle_pressed(first_rendered_patch)

    find('body').send_keys(:arrow_down)
    expect_patch_active(second_rendered_patch)

    find('body').send_keys(:arrow_up)
    expect_patch_active(first_rendered_patch)
  end
end
