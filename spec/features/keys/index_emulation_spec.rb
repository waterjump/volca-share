# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Keys patch index emulation', js: true do
  let!(:first_patch) { create(:user_keys_patch, name: 'First Patch') }
  let!(:second_patch) { create(:user_keys_patch, name: 'Second Patch') }

  def patch_card_selector(patch, active_state)
    ".patch-holder[data-patch-id='#{patch.id}']" \
      "[data-emulation-active='#{active_state}']"
  end

  def emulate_toggle_for(patch)
    find(".keys-emulate-toggle[data-patch-id='#{patch.id}']", visible: :all)
  end

  def musical_typing_toggle
    find('#keys-musical-typing-toggle', visible: :all)
  end

  def musical_typing_container
    find('.keys-index-musical-typing', visible: :all)
  end

  def expect_patch_active(patch)
    expect(page).to have_css(patch_card_selector(patch, 'true'))
  end

  def expect_patch_inactive(patch)
    expect(page).to have_css(patch_card_selector(patch, 'false'))
  end

  before do
    visit keys_patches_path
  end

  it 'starts with no active emulation and hidden musical typing control' do
    expect(page).to have_css(".patch-holder[data-emulation-active='false']", count: 2)
    expect(page).to have_css('.keys-emulate-toggle', count: 2)
    expect(musical_typing_container[:class]).to include('hidden')
    expect(musical_typing_toggle[:'aria-pressed']).to eq('false')
  end

  it 'activates a patch and enables musical typing by default' do
    emulate_toggle_for(first_patch).click

    expect_patch_active(first_patch)
    expect(page).to have_css(
      ".keys-emulate-toggle[data-patch-id='#{first_patch.id}'][aria-pressed='true']"
    )
    expect(musical_typing_container[:class]).not_to include('hidden')
    expect(musical_typing_toggle).not_to be_disabled
    expect(musical_typing_toggle[:'aria-pressed']).to eq('true')
  end

  it 'switches the active emulation to the next patch card' do
    emulate_toggle_for(first_patch).click
    expect_patch_active(first_patch)
    emulate_toggle_for(second_patch).click

    expect_patch_inactive(first_patch)
    expect_patch_active(second_patch)
    expect(page).to have_css(
      ".keys-emulate-toggle[data-patch-id='#{second_patch.id}'][aria-pressed='true']"
    )
    expect(musical_typing_toggle[:'aria-pressed']).to eq('true')
  end

  it 'toggles the active patch off when clicked again' do
    emulate_toggle_for(first_patch).click
    expect_patch_active(first_patch)
    emulate_toggle_for(first_patch).click

    expect_patch_inactive(first_patch)
    expect(musical_typing_container[:class]).to include('hidden')
    expect(musical_typing_toggle[:'aria-pressed']).to eq('false')
  end

  it 'stops the active emulation when escape is pressed' do
    emulate_toggle_for(first_patch).click
    expect_patch_active(first_patch)

    find('body').send_keys(:escape)

    expect_patch_inactive(first_patch)
    expect(musical_typing_container[:class]).to include('hidden')
  end

  it 'moves to the next and previous patch with arrow keys' do
    ordered_cards = all('.patch-holder', minimum: 2, visible: :all)
    first_card = ordered_cards[0]
    second_card = ordered_cards[1]
    first_card_patch_id = first_card['data-patch-id']
    second_card_patch_id = second_card['data-patch-id']

    first_card.find('.keys-emulate-toggle', visible: :all).click
    expect(page).to have_css(
      ".patch-holder[data-patch-id='#{first_card_patch_id}'][data-emulation-active='true']"
    )
    find('body').send_keys(:arrow_down)
    expect(page).to have_css(
      ".patch-holder[data-patch-id='#{second_card_patch_id}'][data-emulation-active='true']"
    )

    find('body').send_keys(:arrow_up)
    expect(page).to have_css(
      ".patch-holder[data-patch-id='#{first_card_patch_id}'][data-emulation-active='true']"
    )
  end
end
