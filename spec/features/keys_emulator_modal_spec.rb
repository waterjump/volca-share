# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Keys emulator modal', type: :feature, js: true do
  let(:page_to_visit) { root_path }
  let(:feature_flag) { 'false' }
  let(:cookie_value) { 'false' }

  before do
    with_modified_env FEATURE_ENABLED_KEYS_EMULATOR_CALLOUT: feature_flag do
      visit page_to_visit
      page.driver.browser.manage.add_cookie(name: 'keysEmulatorCalloutSeen', value: cookie_value)
      visit page_to_visit
    end
  end

  context 'when feature is disabled' do
    it 'does not show modal' do
      expect(page).not_to have_selector('#keys-emulator-callout-modal', visible: false)
    end
  end

  context 'when feature is enabled' do
    let(:feature_flag) { 'true' }

    context 'when page is not keys emulator page' do
      context 'when cookie is not present' do
        it 'shows modal' do
          expect(page).to have_selector('#keys-emulator-callout-modal', visible: false)
        end
      end

      context 'when cookie is present' do
        let(:cookie_value) { 'true' }

        it 'does not show modal' do
          expect(page).not_to have_selector('#keys-emulator-callout-modal', visible: false)
        end
      end
    end

    context 'when page is keys emulator page' do
      let(:page_to_visit) { keys_emulator_path }
      it 'does not show modal' do
        expect(page).not_to have_selector('#keys-emulator-callout-modal', visible: false)
      end
    end
  end
end

