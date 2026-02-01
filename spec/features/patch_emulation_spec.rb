# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bass patch emulation', js: true do
  let(:patch) { FactoryBot.create(:patch) }

  context 'when feature is enabled' do
    it 'links to page that emulates with same parameters' do
      visit patch_path(patch)
      click_link 'Emulate this patch'
      expect(current_path).to eq(bass_emulator_path)
      reflects_emulator_patch(patch)
    end
  end
end
