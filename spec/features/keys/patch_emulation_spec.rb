# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Keys patch emulation', js: true do
  let(:patch) { FactoryBot.create(:keys_patch) }

  context 'when feature is enabled' do
    it 'links to page that emulates with same parameters' do
      visit keys_patch_path(patch)
      click_link 'Emulate this patch'
      expect(current_path).to eq(keys_emulator_path)
      reflects_keys_emulator_patch(patch)
    end
  end
end
